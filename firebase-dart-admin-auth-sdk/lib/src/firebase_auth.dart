import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:firebase_dart_admin_auth_sdk/src/firebase_user/link_with_credentails.dart';

import 'auth/auth_redirect_link.dart';
import 'package:ds_standard_features/ds_standard_features.dart' as http;
import 'package:firebase_dart_admin_auth_sdk/src/auth/generate_custom_token.dart';
import 'package:firebase_dart_admin_auth_sdk/src/service_account.dart';
import 'package:firebase_dart_admin_auth_sdk/src/auth/apply_action_code.dart';
import 'package:firebase_dart_admin_auth_sdk/src/auth/email_password_auth.dart';
import 'package:firebase_dart_admin_auth_sdk/src/auth/custom_token_auth.dart';
import 'package:firebase_dart_admin_auth_sdk/src/auth/email_link_auth.dart';
import 'package:firebase_dart_admin_auth_sdk/src/auth/get_additional_user_info.dart';
import 'package:firebase_dart_admin_auth_sdk/src/auth/link_provider_to_user.dart';
import 'package:firebase_dart_admin_auth_sdk/src/auth/phone_auth.dart';

import 'package:firebase_dart_admin_auth_sdk/src/auth/reload_user.dart';
import 'package:firebase_dart_admin_auth_sdk/src/auth/send_email_verification_code.dart';
import 'package:firebase_dart_admin_auth_sdk/src/auth/set_language_code.dart';
import 'package:firebase_dart_admin_auth_sdk/src/auth/sign_out_auth.dart';
import 'package:firebase_dart_admin_auth_sdk/src/auth/oauth_auth.dart';
import 'package:firebase_dart_admin_auth_sdk/src/auth/unlink_provider.dart';
import 'package:firebase_dart_admin_auth_sdk/src/auth/update_current_user.dart';
import 'package:firebase_dart_admin_auth_sdk/src/auth/update_password.dart';
import 'package:firebase_dart_admin_auth_sdk/src/auth/update_profile.dart';
import 'package:firebase_dart_admin_auth_sdk/src/auth/user_device_language.dart';
import 'package:firebase_dart_admin_auth_sdk/src/auth/verify_before_email_update.dart';
import 'package:firebase_dart_admin_auth_sdk/src/auth/verify_password_reset_code.dart';
import 'package:firebase_dart_admin_auth_sdk/src/firebase_app.dart';
import 'package:firebase_dart_admin_auth_sdk/src/http_response.dart';
import 'package:firebase_dart_admin_auth_sdk/src/user.dart';
import 'package:firebase_dart_admin_auth_sdk/src/user_credential.dart';
import 'package:firebase_dart_admin_auth_sdk/src/exceptions.dart';
import 'package:firebase_dart_admin_auth_sdk/src/auth_credential.dart';

// New imports for Sprint 2 #16 to #21
import 'package:firebase_dart_admin_auth_sdk/src/auth/password_reset_email.dart';
import 'package:firebase_dart_admin_auth_sdk/src/auth/revoke_access_token.dart';
import 'package:firebase_dart_admin_auth_sdk/src/auth/id_token_changed.dart';
import 'package:firebase_dart_admin_auth_sdk/src/auth/auth_state_changed.dart';
import 'package:firebase_dart_admin_auth_sdk/src/utils.dart';

import 'auth/before_auth_state_change.dart';
import 'auth/set_persistence.dart';
import 'auth/sign_in_anonymously.dart';
import 'firebase_user/get_language_code.dart';
import 'auth/auth_link_with_phone_number.dart';

import 'firebase_user/delete_user.dart';

import 'auth/parse_action_code_url.dart';

import 'firebase_user/set_language_code.dart';
import 'id_token_result_model.dart';

///Base Firebase auth class that contains all the methods provided by the sdk
class FirebaseAuth {
  ///THe api key for firebase project
  final String? apiKey;

  ///The project id for your firebase project
  final String? projectId;

  ///The access token to the firebase project
  final String? accessToken;

  /// The service account of your firebase project
  final ServiceAccount? serviceAccount;

  /// The generated custom token
  final GenerateCustomToken? generateCustomToken;

  /// Local httpClient
  late http.Client httpClient;

  ///Projects bucket name
  final String? bucketName;

  /// For performing email and password auth
  late EmailPasswordAuth emailPassword;

  /// For generating customToken
  late CustomTokenAuth customToken;

  /// For sending email Link
  late EmailLinkAuth emailLink;

  /// For performing auth operations pertaing to phone
  late PhoneAuth phone;

  /// For performing auth operations pertaining to external authenticators
  late OAuthAuth oauth;
  late FirebaseSignOut signOUt;
  late SignInWithRedirectService signInRedirect;

  /// Update current User
  late UpdateCurrentUser updateUserService;

  /// Use the language of the device
  late UseDeviceLanguageService useDeviceLanguage;

  /// Verify password reset
  late VerifyPasswordResetCodeService verifyPasswordReset;

  /// Apply Action code
  late ApplyActionCode applyAction;

  late ReloadUser _reloadUser;
  late SendEmailVerificationCode _sendEmailVerificationCode;
  late SetLanguageCode _setLanguageCode;
  late UnlinkProvider _unlinkProvider;
  late UpdatePassword _updatePassword;

  // New service declarations for Sprint 2 #16 to #21
  /// Send Password reset email
  late PasswordResetEmailService passwordResetEmail;

  /// Revoke an access token
  late RevokeAccessTokenService revokeAccessToken;

  /// Listen to token Id change
  late IdTokenChangedService idTokenChanged;

  /// Listen to auth state change
  late AuthStateChangedService authStateChanged;

  //Ticket mo 36 to 41///////////////
  /// Link a phone number to the an account
  late FirebasePhoneNumberLink firebasePhoneNumberLink;

  /// Parase firebase url link
  late FirebaseParseUrlLink firebaseParseUrlLink;

  /// Delete User
  late FirebaseDeleteUser firebaseDeleteUser;
  late LinkWithCredientialClass linkWithCredientialClass;

  late GetAdditionalUserInfo _getAdditionalUserInfo;
  late LinkProviderToUser _linkProviderToUser;
  late UpdateProfile _updateProfile;
  late VerifyBeforeEmailUpdate _verifyBeforeEmailUpdate;

  //Ticketr 5,7,23,24,61
  ///Sign in anonymously
  late FirebaseSignInAnonymously signInAnonymously;

  /// Set persistence
  late PersistenceService setPresistence;

  /// Set language code
  late LanguageService setLanguageService;

  /// Get firebase language code
  late LanguageGetService getLanguageService;

  /// Firebase before auth change
  late FirebaseBeforeAuthStateChangeService
      firebaseBeforeAuthStateChangeService;

  /// Current firebase auth user
  User? currentUser;

  /// StreamControllers for managing auth state
  final StreamController<User?> authStateChangedController =
      StreamController<User?>.broadcast();

  /// Stream Controller for manageing id token change events
  final StreamController<User?> idTokenChangedController =
      StreamController<User?>.broadcast();

  /// Firebae Auth constructor class
  FirebaseAuth({
    this.apiKey,
    this.projectId,
    http.Client? httpClient, // Add this parameter
    this.bucketName,
    this.accessToken,
    this.serviceAccount,
    this.generateCustomToken,
  }) {
    this.httpClient = httpClient ??
        http.Client(); // Use the injected client or default to a new one
    emailPassword = EmailPasswordAuth(this);
    customToken = CustomTokenAuth(this);
    emailLink = EmailLinkAuth(this);
    phone = PhoneAuth(this);
    oauth = OAuthAuth(this);
    signOUt = FirebaseSignOut();
    signInRedirect = SignInWithRedirectService(auth: this);
    updateUserService = UpdateCurrentUser(auth: this);
    useDeviceLanguage = UseDeviceLanguageService(auth: this);
    verifyPasswordReset = VerifyPasswordResetCodeService(auth: this);
    applyAction = ApplyActionCode(this);

    _reloadUser = ReloadUser(auth: this);
    _sendEmailVerificationCode = SendEmailVerificationCode(auth: this);
    _setLanguageCode = SetLanguageCode(auth: this);
    _unlinkProvider = UnlinkProvider(auth: this);
    _updatePassword = UpdatePassword(auth: this);

    // New service initializations for Sprint 2 #16 to #21
    passwordResetEmail = PasswordResetEmailService(auth: this);
    revokeAccessToken = RevokeAccessTokenService(auth: this);
    idTokenChanged = IdTokenChangedService(auth: this);
    authStateChanged = AuthStateChangedService(auth: this);
    applyAction = ApplyActionCode(this);

    firebasePhoneNumberLink = FirebasePhoneNumberLink(this);
    firebaseParseUrlLink = FirebaseParseUrlLink(auth: this);
    firebaseDeleteUser = FirebaseDeleteUser(auth: this);
    linkWithCredientialClass = LinkWithCredientialClass(auth: this);

    _getAdditionalUserInfo = GetAdditionalUserInfo(auth: this);
    _linkProviderToUser = LinkProviderToUser(auth: this);
    _updateProfile = UpdateProfile(this);
    _verifyBeforeEmailUpdate = VerifyBeforeEmailUpdate(this);
    signInAnonymously = FirebaseSignInAnonymously(this);
    setPresistence = PersistenceService(auth: this);
    setLanguageService = LanguageService(auth: this);
    getLanguageService = LanguageGetService(auth: this);
    firebaseBeforeAuthStateChangeService =
        FirebaseBeforeAuthStateChangeService(this);
  }

  /// Base function for http calls
  Future<HttpResponse> performRequest(
      String endpoint, Map<String, dynamic> body) async {
    //log(apiKey.toString());
    final url = Uri.https(
      'identitytoolkit.googleapis.com',
      '/v1/accounts:$endpoint',
      {
        'key': apiKey,
      },
    );

    final response =
        await httpClient.post(url, body: json.encode(body), headers: {
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    });

    if (response.statusCode != 200) {
      final error = json.decode(response.body)['error'];
      log("error is $error ");
      throw FirebaseAuthException(
        code: error['message'],
        message: error['message'],
      );
    }
    return HttpResponse(
        statusCode: response.statusCode, body: json.decode(response.body));
  }

  /// updateCurrentUser method to automatically trigger the streams
  void updateCurrentUser(User user) {
    currentUser = currentUser == null ? user : currentUser?.copyWith(user);
    authStateChangedController.add(currentUser);
    idTokenChangedController.add(currentUser);
  }

  /// Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) {
    return emailPassword.signIn(email, password);
  }

  /// Create user with email and password
  Future<UserCredential?> createUserWithEmailAndPassword(
      String email, String password) {
    return emailPassword.signUp(email, password);
  }

  /// Sign in with custom token
  Future<UserCredential> signInWithCustomToken(String? uid) async {
    assert(serviceAccount != null, 'Service Account cannot be null');
    assert(generateCustomToken != null, 'Custom token cannot be null');

    String token =
        await generateCustomToken!.generateSignInJwt(serviceAccount!, uid: uid);
    return customToken.signInWithCustomToken(token);
  }

  ///Sign in with credentials
  Future<UserCredential?> signInWithCredential(
      AuthCredential credential) async {
    if (credential is EmailAuthCredential) {
      return signInWithEmailAndPassword(credential.email, credential.password);
    } else if (credential is PhoneAuthCredential) {
      return signInWithPhoneNumber(
          credential.verificationId, credential.smsCode);
    } else if (credential is OAuthCredential) {
      return signInWithPopup(
        credential.providerId,
      );
    } else {
      throw FirebaseAuthException(
        code: 'unsupported-credential',
        message: 'Unsupported credential type',
      );
    }
  }

  /// Sign in with pop up
  Future<UserCredential> signInWithPopup(String providerId) {
    return oauth.signInWithPopup(providerId);
  }

  ///Sign in with phone number
  Future<UserCredential> signInWithPhoneNumber(
      String verificationId, String smsCode) {
    return phone.verifyPhoneNumber(verificationId, smsCode);
  }

  /// Sign in with email link
  Future<UserCredential> signInWithEmailLink(
      String email, String emailLinkUrl) {
    return emailLink.signInWithEmailLink(email, emailLinkUrl);
  }

  /// Sign out
  Future<void> signOut() async {
    log("hekko");
    log("hekko${FirebaseApp.instance.getCurrentUser()}");
    if (FirebaseApp.instance.getCurrentUser() == null) {
      throw FirebaseAuthException(
        code: 'user-not-signed-in',
        message: 'No user is currently signed in.',
      );
    }

    try {
      await signOUt.signOut();
      FirebaseApp.instance.setCurrentUser(null);
      currentUser = null;
      log('User Signout ');
      return;
    } catch (e) {
      log('Sign-out failed: $e');
      throw FirebaseAuthException(
        code: 'sign-out-error',
        message: 'Failed to sign out user.',
      );
    }
  }

  Future<UserCredential?> signInWithRedirect(
      String redirectUri, String idToken, String providerId) async {
    try {
      return await signInRedirect.signInWithRedirect(
        redirectUri,
        idToken,
        providerId,
      );
    } catch (e) {
      print('Sign-in with redirect failed: $e');
      throw FirebaseAuthException(
        code: 'sign-in-redirect-error',
        message: 'Failed to sign in with redirect.',
      );
    }
  }

  Future<void> updateUserInformation(
      String userId, String idToken, Map<String, dynamic> userData) async {
    try {
      await updateUserService.updateCurrentUser(userId, idToken, userData);
    } catch (e) {
      print('Update current user information failed: $e');
      throw FirebaseAuthException(
        code: 'update-current-user-error',
        message: 'Failed to update current user information.',
      );
    }
  }

  /// Set device language
  Future<void> deviceLanguage(String languageCode) async {
    try {
      await useDeviceLanguage.useDeviceLanguage(
          currentUser!.idToken!, languageCode);
    } catch (e) {
      print('Use device language failed: $e');
      throw FirebaseAuthException(
        code: 'use-device-language-error',
        message: 'Failed to set device language.',
      );
    }
  }

  Future<String?> verifyPasswordResetCode(String code) async {
    try {
      return await verifyPasswordReset.verifyPasswordResetCode(code);
    } catch (e) {
      print('Verify password reset code failed: $e');
      throw FirebaseAuthException(
        code: 'verify-password-reset-code-error',
        message: 'Failed to verify password reset code.',
      );
    }
  }

  ///Apply action code
  Future<bool> applyActionCode(String actionCode) {
    return applyAction.applyActionCode(actionCode);
  }

  ///Reload/Refresh user
  Future<User> reloadUser() {
    return _reloadUser.reloadUser(
      currentUser?.idToken,
    );
  }

  ///Send verification code to user email
  Future<void> sendEmailVerificationCode() {
    return _sendEmailVerificationCode
        .sendEmailVerificationCode(currentUser?.idToken);
  }

  ///Set language code
  Future<User> setLanguageCode(String languageCode) {
    return _setLanguageCode.setLanguageCode(
      currentUser?.idToken,
      languageCode,
    );
  }

  /// Unlink a provider
  Future<User> unlinkProvider(String providerId) {
    return _unlinkProvider.unlinkProvider(
      currentUser?.idToken,
      providerId,
    );
  }

  /// Update password
  Future<User> updatePassword(String newPassowrd) {
    return _updatePassword.updatePassword(
      newPassowrd,
      currentUser?.idToken,
    );
  }

  // New methods with complete functionality Sprint 2 #16 to #21

  /// Sends a password reset email to the specified email address.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await passwordResetEmail.sendPasswordResetEmail(email);
    } catch (e) {
      throw FirebaseAuthException(
        code: 'password-reset-error',
        message: 'Failed to send password reset email: ${e.toString()}',
      );
    }
  }

  /// Revokes the specified access token.
  Future<void> revokeToken(String idToken) async {
    try {
      await revokeAccessToken.revokeToken(idToken);
    } catch (e) {
      throw FirebaseAuthException(
        code: 'token-revocation-error',
        message: 'Failed to revoke access token: ${e.toString()}',
      );
    }
  }

  /// Returns a stream of User objects when the ID token changes.
  Stream<User?> onIdTokenChanged() {
    return idTokenChangedController.stream;
  }

  /// Returns a stream of User objects when the auth state changes.
  Stream<User?> onAuthStateChanged() {
    return authStateChangedController.stream;
  }

  /// Checks if the provided URL is a valid sign-in link for email authentication.
  bool isSignInWithEmailLink(String emailLink) {
    return this.emailLink.isSignInWithEmailLink(emailLink);
  }

  /// Sends a sign-in link to the specified email address using the provided ActionCodeSettings.
  Future<void> sendSignInLinkToEmail(String email,
      {ActionCodeSettings? actionCode}) {
    return emailLink.sendSignInLinkToEmail(
      email,
      actionCode: actionCode,
    );
  }

  Future<UserCredential?> linkAccountWithCredientials(
      String redirectUri, String idToken, String providerId) async {
    try {
      return await linkWithCredientialClass.linkWithCrediential(
        redirectUri,
        idToken,
        providerId,
      );
    } catch (e) {
      print('Sign-in with redirect failed: $e');
      throw FirebaseAuthException(
        code: 'sign-in-redirect-error',
        message: 'Failed to sign in with redirect.',
      );
    }
  }

  /// Get additonal User info
  Future<User> getAdditionalUserInfo() async {
    return await _getAdditionalUserInfo.getAdditionalUserInfo(
      currentUser?.idToken,
    );
  }

  ///Link provider to user
  Future<bool> linkProviderToUser(
    String providerId,
    String providerIdToken,
  ) async {
    return _linkProviderToUser.linkProviderToUser(
      currentUser?.idToken,
      providerId,
      providerIdToken,
    );
  }

  ///Update profile
  Future<User> updateProfile(
    String displayName,
    String displayImage,
  ) async {
    return await _updateProfile.updateProfile(
      displayName,
      displayImage,
      currentUser?.idToken,
    );
  }

  ///Verify before email update
  Future<bool> verifyBeforeEmailUpdate(
    String newEmail, {
    ActionCodeSettings? action,
  }) async {
    return await _verifyBeforeEmailUpdate.verifyBeforeEmailUpdate(
      currentUser?.idToken,
      newEmail,
      action: action,
    );
  }

  ///Parse a Firebase action code URL
  Future<dynamic> parseActionCodeUrl(String url) async {
    Uri uri = Uri.parse(url);

    if (uri.queryParameters.isEmpty) {
      return null;
    }

    // Extract query parameters
    String? mode = uri.queryParameters['mode'];
    String? oobCode = uri.queryParameters['oobCode'];
    String? continueUrl = uri.queryParameters['continueUrl'];
    String? lang = uri.queryParameters['lang'];

    if (mode == null || oobCode == null) {
      return null;
    }

    // Return the parsed parameters as a map
    return {
      'mode': mode,
      'oobCode': oobCode,
      'continueUrl': continueUrl ?? '',
      'lang': lang ?? '',
    };
  }

  ///FirebaseUser phone number link
  Future<void> firebasePhoneNumberLinkMethod(
      String phone, String verificationCode) async {
    try {
      await firebasePhoneNumberLink.linkPhoneNumber(
          currentUser!.idToken!, phone, verificationCode);
    } catch (e) {
      log("error is $e");
      throw FirebaseAuthException(
        code: 'verification-code-error',
        message:
            'Failed to send verification code to phone number: ${e.toString()}',
      );
    }
  }

  ///FirebaseUser.deleteUser
  Future<void> deleteFirebaseUser() async {
    if (FirebaseApp.instance.getCurrentUser() == null && currentUser == null) {
      throw FirebaseAuthException(
        code: 'user-not-signed-in',
        message: 'No user is currently signed in.',
      );
    }
    // var accesToken = FirebaseAppInitialize.instance.getAccessToken();
    //  log("access token is$accesToken");
    try {
      await firebaseDeleteUser.deleteUser(
          currentUser!.idToken!, currentUser!.uid);
      FirebaseApp.instance.setCurrentUser(null);
      log('User Deleted ');
      return;
    } catch (e) {
      log('User Delete failed: $e');
      throw FirebaseAuthException(
        code: 'user-delete-error',
        message: 'Failed to delete user.',
      );
    }
  }

  /////////FirebaseUser.getIdToken
  Future<String?> getIdToken() async {
    final user = currentUser;
    return await user?.getIdToken();
  }

  //////////// FirebaseUser.getIdTokenResult
  Future<IdTokenResult?> getIdTokenResult() async {
    final user = currentUser;
    return await user?.getIdTokenResult();
  }

/////////////////Firebase SignIn Anonymously /////////////////////////

  Future<UserCredential?> signInAnonymouslyMethod() async {
    try {
      return await signInAnonymously.signInAnonymously();
    } catch (e) {
      print('Sign-in with anonymously failed: $e');
      throw FirebaseAuthException(
        code: 'sign-in-anonymously-error',
        message: 'Failed to sign in with anonymously.',
      );
    }
  }

///////////////////////////////
  ///////////////////////////////
  Future<void> setPresistanceMethod(
      String presistanceType, String databaseName) {
    try {
      return setPresistence.setPersistence(currentUser!.uid,
          currentUser!.idToken!, presistanceType, databaseName);
    } catch (e) {
      print('Failed Set Persistence: $e');
      throw FirebaseAuthException(
        code: 'set-persistence-error',
        message: 'Failed to Set Persistence.',
      );
    }
  }

/////////////////
  Future<void> setLanguageCodeMethod(String languageCode, String dataBaseName) {
    try {
      return setLanguageService.setLanguagePreference(
          currentUser!.uid, currentUser!.idToken!, languageCode, dataBaseName);
    } catch (e) {
      print('Failed Set Language: $e');
      throw FirebaseAuthException(
        code: 'set-language-error',
        message: 'Failed to set language.',
      );
    }
  }

  ///////////////////
  Future<void> getLanguageCodeMethod(String databaseName) {
    try {
      return getLanguageService.getLanguagePreference(
          currentUser!.uid, currentUser!.idToken!, databaseName);
    } catch (e) {
      // print('Failed to Get Set Language: $e');
      throw FirebaseAuthException(
        code: 'get-language-error',
        message: 'No language is set ',
      );
    }
  }

  ////////
  Future<void> getAuthBeforeChange() {
    try {
      return firebaseBeforeAuthStateChangeService.beforeAuthStateChange(
        currentUser!.idToken!,
        currentUser!.refreshToken!,
      );
    } catch (e) {
      print('Failed Before Auth State Changed: $e');
      throw FirebaseAuthException(
        code: 'before-auth-state-changed-error',
        message: 'Failed to Before Auth State Changed.',
      );
    }
  }

  /// Disposes of the FirebaseAuth instance and releases resources.
  void dispose() {
    authStateChangedController.close();
    idTokenChangedController.close();
    httpClient.close();
  }
}
