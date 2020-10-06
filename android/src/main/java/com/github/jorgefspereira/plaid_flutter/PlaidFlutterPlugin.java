package com.github.jorgefspereira.plaid_flutter;

import android.app.Activity;
import android.content.Intent;
import android.util.Log;

import java.util.Map;
import java.util.HashMap;
import java.util.ArrayList;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.plugin.common.BinaryMessenger;

import kotlin.Unit;
import kotlin.jvm.functions.Function1;

import com.plaid.link.Plaid;
import com.plaid.link.configuration.LinkConfiguration;
import com.plaid.link.configuration.LinkLogLevel;
import com.plaid.link.configuration.LinkTokenConfiguration;
import com.plaid.link.configuration.PlaidEnvironment;
import com.plaid.link.configuration.PlaidProduct;
import com.plaid.link.event.LinkEvent;
import com.plaid.link.event.LinkEventMetadata;
import com.plaid.link.result.LinkAccount;
import com.plaid.link.result.LinkError;
import com.plaid.link.result.LinkExit;
import com.plaid.link.result.LinkExitMetadata;
import com.plaid.link.result.LinkSuccess;
import com.plaid.link.result.LinkSuccess.LinkSuccessMetadata;
import com.plaid.link.result.PlaidLinkResultHandler;

import org.json.JSONObject;

/** PlaidFlutterPlugin */
public class PlaidFlutterPlugin implements MethodCallHandler, PluginRegistry.ActivityResultListener {

  private static final String CHANNEL_NAME = "plugins.flutter.io/plaid_flutter";

  /// LinkConfiguration
  private static final String CLIENT_NAME = "clientName";
  private static final String PRODUCTS = "products";
  private static final String ENV = "env";
  private static final String ACCOUNT_SUBTYPES = "accountSubtypes";
  private static final String USER_EMAIL_ADDRESS = "userEmailAddress";
  private static final String USER_LEGAL_NAME = "userLegalName";
  private static final String USER_PHONE_NUMBER = "userPhoneNumber";
  private static final String WEBHOOK = "webhook";
  private static final String LINK_CUSTOMIZATION_NAME = "linkCustomizationName";
  private static final String LANGUAGE = "language";
  private static final String COUNTRY_CODES = "countryCodes";
  private static final String LINK_TOKEN = "linkToken";
  private static final String PUBLIC_KEY = "publicKey";
  private static final String PAYMENT_TOKEN = "paymentToken";

  /// PlaidLinkResultHandler
  private static final String ON_SUCCESS_METHOD = "onSuccess";
  private static final String ON_EXIT_METHOD = "onExit";
  private static final String ON_EVENT_METHOD = "onEvent";
  private static final String ERROR = "error";
  private static final String METADATA = "metadata";
  private static final String PUBLIC_TOKEN = "publicToken";
  private static final String EVENT = "event";

  private Activity activity;
  private MethodChannel channel;

  private PlaidLinkResultHandler plaidLinkResultHandler = new PlaidLinkResultHandler(
      new Function1<LinkSuccess, Unit>() {
        @Override
        public Unit invoke(LinkSuccess e) {
          Map<String, Object> data = new HashMap<>();

          data.put(PUBLIC_TOKEN, e.getPublicToken());
          data.put(METADATA, createMapFromConnectionMetadata(e.getMetadata()));

          channel.invokeMethod(ON_SUCCESS_METHOD, data);
          return Unit.INSTANCE;
        }
      },
      new Function1<LinkExit, Unit>() {
        @Override
        public Unit invoke(LinkExit e) {

          Map<String, Object> data = new HashMap<>();
          data.put(METADATA, createMapFromExitMetadata(e.getMetadata()));

          LinkError error = e.getError();

          if(error != null) {
            data.put(ERROR, error.getErrorMessage());
          }

          channel.invokeMethod(ON_EXIT_METHOD, data);
          return Unit.INSTANCE;
        }
      }
  );

  public static void registerWith(Registrar registrar) {
    if (registrar.activity() == null) {
      return;
    }

    final PlaidFlutterPlugin plugin = new PlaidFlutterPlugin();
    plugin.initializePlugin(registrar.activity(), registrar.messenger());
    registrar.addActivityResultListener(plugin);
  }

  private void initializePlugin(Activity activity, BinaryMessenger messenger) {
    this.activity = activity;

    this.channel = new MethodChannel(messenger, CHANNEL_NAME);
    channel.setMethodCallHandler(this);

    Plaid.initialize(activity.getApplication());
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    if(call.method.equals("open")) {
      Plaid.setLinkEventListener(new Function1<LinkEvent, Unit>() {
        @Override
        public Unit invoke(LinkEvent e) {
          Map<String, Object> data = new HashMap<>();
          data.put(EVENT, e.getEventName().toString());
          data.put(METADATA, createMapFromEventMetadata(e.getMetadata()));

          channel.invokeMethod(ON_EVENT_METHOD, data);
          return Unit.INSTANCE;
        }
      });

      Map<String, Object> arguments = call.arguments();
      String linkToken = (String) arguments.get(LINK_TOKEN);
      LinkConfiguration configuration = linkToken != null && linkToken.startsWith("link-") ? getNewLinkConfiguration(arguments) : getLegacyLinkConfiguration(arguments);
      Plaid.openLink(activity, configuration);
    }
    else if(call.method.equals("close")) {
      
    }
    else {
      result.notImplemented();
    }
  }

  @Override
  public boolean onActivityResult(int requestCode, int resultCode, Intent intent) {
    return plaidLinkResultHandler.onActivityResult(requestCode, resultCode, intent);
  }

  private LinkConfiguration getNewLinkConfiguration(Map<String, Object> arguments) {
    String linkToken = (String) arguments.get(LINK_TOKEN);

    LinkTokenConfiguration.Builder configuration = new LinkTokenConfiguration.Builder()
            .token(linkToken)
            .logLevel(BuildConfig.DEBUG ? LinkLogLevel.DEBUG : LinkLogLevel.ASSERT);

    return configuration.build().toLinkConfiguration();
  }

  private LinkConfiguration getLegacyLinkConfiguration(Map<String, Object> arguments) {

    String clientName = (String) arguments.get(CLIENT_NAME);
    String publicKey = (String) arguments.get(PUBLIC_KEY);
    String envString = (String) arguments.get(ENV);
    String language = (String) arguments.get(LANGUAGE);
    String linkCustomizationName = (String) arguments.get(LINK_CUSTOMIZATION_NAME);
    String webhook = (String) arguments.get(WEBHOOK);
    String userLegalName = (String) arguments.get(USER_LEGAL_NAME);
    String userEmailAddress = (String) arguments.get(USER_EMAIL_ADDRESS);
    String userPhoneNumber = (String) arguments.get(USER_PHONE_NUMBER);
    String paymentToken = (String) arguments.get(PAYMENT_TOKEN);
    String token = (String) arguments.get(LINK_TOKEN);
    ArrayList<String> countryCodes = (ArrayList<String>) arguments.get(COUNTRY_CODES);
    ArrayList<?> productsObjects = (ArrayList<?>)arguments.get(PRODUCTS);
    Map<String, ArrayList<String>> accountSubtypes = (Map<String, ArrayList<String>>) arguments.get(ACCOUNT_SUBTYPES);

    PlaidEnvironment env = PlaidEnvironment.valueOf(envString.toUpperCase());

    LinkConfiguration.Builder configuration = new LinkConfiguration.Builder()
            .publicKey(publicKey)
            .clientName(clientName)
            .logLevel(BuildConfig.DEBUG ? LinkLogLevel.DEBUG : LinkLogLevel.ASSERT);

    ArrayList<PlaidProduct> products = new ArrayList<>();


    for (Object po : productsObjects) {
      String ps = (String)po;
      PlaidProduct p = PlaidProduct.valueOf(ps.toUpperCase());
      products.add(p);
    }

    configuration.products(products);

    if(accountSubtypes != null) {
      Map<String, String> extraParams = new HashMap<>();
      JSONObject json = new JSONObject(accountSubtypes);
      extraParams.put(ACCOUNT_SUBTYPES, json.toString());
      configuration.extraParams(extraParams);
    }

    if(env != null) {
      configuration.environment(env);
    }

    if(linkCustomizationName != null) {
      configuration.linkCustomizationName(linkCustomizationName);
    }

    if(language != null) {
      configuration.language(language);
    }

    if(countryCodes != null) {
      configuration.countryCodes(countryCodes);
    }

    if(webhook != null) {
      configuration.webhook(webhook);
    }

    if(paymentToken != null) {
      configuration.paymentToken(paymentToken);
    }

    if(userLegalName != null) {
      configuration.userLegalName(userLegalName);
    }

    if(userEmailAddress != null) {
      configuration.userEmailAddress(userEmailAddress);
    }

    if(userPhoneNumber != null) {
      configuration.userPhoneNumber(userPhoneNumber);
    }
    
    if(token != null) {
      configuration.token(token);
    }

    return configuration.build();
  }

  private Map<String, String> createMapFromEventMetadata(LinkEventMetadata data) {
    Map<String, String> result = new HashMap<>();

    result.put("institution_name", data.getInstitutionName());
    result.put("mfa_type", data.getMfaType());
    result.put("request_id", data.getRequestId());
    result.put("error_message", data.getErrorMessage());
    result.put("timestamp", data.getTimestamp());
    result.put("link_session_id", data.getLinkSessionId());
    result.put("error_code", data.getErrorCode());
    result.put("exit_status", data.getExitStatus());
    result.put("institution_id", data.getInstitutionId());
    result.put("institution_search_query", data.getInstitutionSearchQuery());

    result.put("view_name", data.getViewName().getJsonValue());
    result.put("error_type", data.getErrorType());

    return result;
  }

  private Map<String, Object> createMapFromConnectionMetadata(LinkSuccessMetadata data) {
    Map<String, Object> result = new HashMap<>();

    Map<String, String> institution = new HashMap<>();
    institution.put("name", data.getInstitutionName());
    institution.put("institution_id", data.getInstitutionId());

    result.put("institution", institution);
    result.put("link_session_id", data.getLinkSessionId());

    ArrayList<Object> accounts = new ArrayList<>();

    for (LinkAccount a: data.getAccounts()) {
      Map<String, String> aux = new HashMap<>();
      aux.put("id", a.getAccountId());
      aux.put("mask", a.getAccountNumber());
      aux.put("name", a.getAccountName());
      aux.put("type", a.getAccountType());
      aux.put("subtype", a.getAccountSubType());
      aux.put("verification_status", a.getVerificationStatus());
      accounts.add(aux);
    }

    result.put("accounts", accounts);

    return result;
  }

  private Map<String, Object> createMapFromExitMetadata(LinkExitMetadata data) {
    Map<String, Object> result = new HashMap<>();

    Map<String, String> institution = new HashMap<>();
    institution.put("name", data.getInstitutionName());
    institution.put("institution_id", data.getInstitutionId());

    result.put("institution", institution);
    result.put("request_id", data.getRequestId());
    result.put("link_session_id", data.getLinkSessionId());
    result.put("status", data.getExitStatus());

    return result;
  }
}

