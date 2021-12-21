package com.github.jorgefspereira.plaid_flutter;

import android.app.Application;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

import java.util.Map;
import java.util.HashMap;
import java.util.ArrayList;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.plugin.common.PluginRegistry.ActivityResultListener;
import io.flutter.plugin.common.BinaryMessenger;

import kotlin.Unit;

import com.plaid.link.Plaid;
import com.plaid.link.configuration.LinkPublicKeyConfiguration;
import com.plaid.link.configuration.LinkTokenConfiguration;
import com.plaid.link.configuration.PlaidEnvironment;
import com.plaid.link.configuration.PlaidProduct;
import com.plaid.link.result.LinkAccount;
import com.plaid.link.result.LinkAccountSubtype;
import com.plaid.link.result.LinkError;
import com.plaid.link.result.LinkExitMetadata;
import com.plaid.link.event.LinkEventMetadata;
import com.plaid.link.result.LinkSuccessMetadata;
import com.plaid.link.result.LinkResultHandler;

/** PlaidFlutterPlugin */
public class PlaidFlutterPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware, ActivityResultListener {

  private static final String CHANNEL_NAME = "plugins.flutter.io/plaid_flutter";

  /// LinkConfiguration
  private static final String PUBLIC_KEY = "publicKey";
  private static final String TOKEN = "token";
  private static final String CLIENT_NAME = "clientName";
  private static final String PRODUCTS = "products";
  private static final String ENVIRONMENT = "environment";
  private static final String ACCOUNT_SUBTYPES = "accountSubtypes";
  private static final String WEBHOOK = "webhook";
  private static final String LINK_CUSTOMIZATION_NAME = "linkCustomizationName";
  private static final String LANGUAGE = "language";
  private static final String COUNTRY_CODES = "countryCodes";
  private static final String USER_EMAIL_ADDRESS = "userEmailAddress";
  private static final String USER_LEGAL_NAME = "userLegalName";
  private static final String USER_PHONE_NUMBER = "userPhoneNumber";
  private static final String TYPE = "type";
  private static final String SUBTYPE = "subtype";
  private static final String NO_LOADING_STATE = "noLoadingState";

  /// LinkResultHandler
  private static final String METHOD_ON_SUCCESS = "onSuccess";
  private static final String METHOD_ON_EXIT = "onExit";
  private static final String METHOD_ON_EVENT = "onEvent";
  private static final String KEY_ERROR = "error";
  private static final String KEY_METADATA = "metadata";
  private static final String KEY_PUBLIC_TOKEN = "publicToken";
  private static final String KEY_EVENT = "event";

  // Prefix
  private static final String LINK_TOKEN_PREFIX = "link-";

  private ActivityPluginBinding binding;
  private Context context;
  private MethodChannel channel;

  private LinkResultHandler resultHandler = new LinkResultHandler(
      linkSuccess -> {
        Map<String, Object> data = new HashMap<>();

        data.put(KEY_PUBLIC_TOKEN, linkSuccess.getPublicToken());
        data.put(KEY_METADATA, mapFromSuccessMetadata(linkSuccess.getMetadata()));

        channel.invokeMethod(METHOD_ON_SUCCESS, data);
        return Unit.INSTANCE;
      },
      linkExit -> {
        Map<String, Object> data = new HashMap<>();
        data.put(KEY_METADATA, mapFromExitMetadata(linkExit.getMetadata()));

        LinkError error = linkExit.getError();

        if(error != null) {
          data.put(KEY_ERROR, mapFromError(error));
        }

        channel.invokeMethod(METHOD_ON_EXIT, data);
        return Unit.INSTANCE;
      }
  );

  public static void registerWith(Registrar registrar) {
    final PlaidFlutterPlugin plugin = new PlaidFlutterPlugin();
    plugin.onAttachedToEngine(registrar.context(), registrar.messenger());
  }

  @Override
  public void onAttachedToEngine(FlutterPluginBinding binding) {
    onAttachedToEngine(binding.getApplicationContext(), binding.getBinaryMessenger());
  }

  @Override
  public void onDetachedFromEngine(FlutterPluginBinding binding) {
    this.context = null;
    this.channel.setMethodCallHandler(null);
    this.channel = null;
  }

  private void onAttachedToEngine(Context context, BinaryMessenger messenger) {
    this.context = context;
    this.channel = new MethodChannel(messenger, CHANNEL_NAME);
    this.channel.setMethodCallHandler(this);
  }

  /// MethodCallHandler

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    if(call.method.equals("open")) {
      this.open(call.arguments());
    }
    else if(call.method.equals("close")) {
      this.close();
    }
    else {
      result.notImplemented();
    }
  }

  /// ActivityAware

  @Override
  public void onAttachedToActivity(ActivityPluginBinding binding) {
    this.binding = binding;
    this.binding.addActivityResultListener(this);
  }

  @Override
  public void onDetachedFromActivity() {
    this.binding.removeActivityResultListener(this);
    this.binding = null;
  }

  @Override
  public void onReattachedToActivityForConfigChanges(ActivityPluginBinding binding) {
    onAttachedToActivity(binding);
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    onDetachedFromActivity();
  }

  /// ActivityResultListener

  @Override
  public boolean onActivityResult(int requestCode, int resultCode, Intent intent) {
    return resultHandler.onActivityResult(requestCode, resultCode, intent);
  }

  private void open(Map<String, Object> arguments) {
    if (binding == null || binding.getActivity() == null) {
      Log.w("PlaidFlutterPlugin", "Activity not attached");
      throw new IllegalStateException("Activity not attached");
    }

    Plaid.setLinkEventListener( linkEvent -> {
      Map<String, Object> data = new HashMap<>();
      data.put(KEY_EVENT, linkEvent.getEventName().toString());
      data.put(KEY_METADATA, mapFromEventMetadata(linkEvent.getMetadata()));

      channel.invokeMethod(METHOD_ON_EVENT, data);
      return Unit.INSTANCE;
    });

    String publicKey = (String) arguments.get(PUBLIC_KEY);
    String token = (String) arguments.get(TOKEN);

    if (publicKey == null && token == null) {
      Log.w("PlaidFlutterPlugin", "Token must be part of configuration.");
      throw new IllegalArgumentException("Token must be part of configuration.");
    }

    if(publicKey != null) {
      Log.d("PlaidFlutterPlugin", "OPEN");
      try {
        Plaid.create(
                (Application)context.getApplicationContext(),
                getLegacyLinkConfiguration(arguments)
        ).open(binding.getActivity());
        return;
      } catch (Exception e) {
        Log.w("PlaidFlutterPlugin", e.getMessage());
        throw e;
      }
    }

    if(token != null) {
      Plaid.create(
              (Application)context.getApplicationContext(),
              getLinkTokenConfiguration(arguments)
      ).open(binding.getActivity());
      return;
    }
  }

  private void close() {

  }

  private LinkTokenConfiguration getLinkTokenConfiguration(Map<String, Object> arguments) {
    String token = (String) arguments.get(TOKEN);

    if (token == null) {
      return null;
    }

    if (!token.startsWith(LINK_TOKEN_PREFIX)) {
      return null;
    }

    LinkTokenConfiguration.Builder configuration = new LinkTokenConfiguration.Builder();

    configuration.token(token);

    if (arguments.containsKey(NO_LOADING_STATE)) {
      configuration.noLoadingState((boolean) arguments.get(NO_LOADING_STATE));
    }

    return configuration.build();
  }

  private LinkPublicKeyConfiguration getLegacyLinkConfiguration(Map<String, Object> arguments) {
    // required arguments for configuration
    String clientName = (String) arguments.get(CLIENT_NAME);
    String publicKey = (String) arguments.get(PUBLIC_KEY);

    LinkPublicKeyConfiguration.Builder configuration = new LinkPublicKeyConfiguration.Builder()
            .publicKey(publicKey)
            .clientName(clientName);

    // optional arguments for configuration
    String language = (String) arguments.get(LANGUAGE);
    String linkCustomizationName = (String) arguments.get(LINK_CUSTOMIZATION_NAME);
    String webhook = (String) arguments.get(WEBHOOK);
    String userLegalName = (String) arguments.get(USER_LEGAL_NAME);
    String userEmailAddress = (String) arguments.get(USER_EMAIL_ADDRESS);
    String userPhoneNumber = (String) arguments.get(USER_PHONE_NUMBER);
    String token = (String) arguments.get(TOKEN);
    String environment = (String) arguments.get(ENVIRONMENT);
    ArrayList<String> countryCodes = (ArrayList<String>) arguments.get(COUNTRY_CODES);
    ArrayList<Map<String, String>> accountSubtypes = (ArrayList<Map<String, String>>) arguments.get(ACCOUNT_SUBTYPES);
    ArrayList<String> products = (ArrayList<String>)arguments.get(PRODUCTS);

    if (products != null) {
      ArrayList<PlaidProduct> listProducts = new ArrayList<>();

      for (String item : products) {
        PlaidProduct p = PlaidProduct.valueOf(item.toUpperCase());
        listProducts.add(p);
      }

      configuration.products(listProducts);
    }

    if(accountSubtypes != null) {
      ArrayList<LinkAccountSubtype> listSubtypes = new ArrayList<>();

      for (Map<String, String> item: accountSubtypes) {
        String type = item.get(TYPE);
        String subtype = item.get(SUBTYPE);
        listSubtypes.add(LinkAccountSubtype.Companion.convert(type, subtype));
      }

      if(!listSubtypes.isEmpty()) {
        configuration.accountSubtypes(listSubtypes);
      }
    }

    if(environment != null) {
      PlaidEnvironment env = PlaidEnvironment.valueOf(environment.toUpperCase());
      configuration.environment(env);
    }

    if(countryCodes != null) {
      configuration.countryCodes(countryCodes);
    }

    if(token != null) {
      configuration.token(token);
    }

    if(linkCustomizationName != null) {
      configuration.linkCustomizationName(linkCustomizationName);
    }

    if(language != null) {
      configuration.language(language);
    }

    if(webhook != null) {
      configuration.webhook(webhook);
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

    return configuration.build();
  }

  private Map<String, String> mapFromError(LinkError error) {
    Map<String, String> result = new HashMap<>();

    result.put("errorType", ""); //TODO:
    result.put("errorCode", error.getErrorCode() == null ? "" : error.getErrorCode().getJson());
    result.put("errorMessage", error.getErrorMessage());
    result.put("errorDisplayMessage", error.getDisplayMessage());

    return result;
  }

  private Map<String, String> mapFromEventMetadata(LinkEventMetadata data) {
    Map<String, String> result = new HashMap<>();

    result.put("errorType", data.getErrorType());
    result.put("errorCode", data.getErrorCode());
    result.put("errorMessage", data.getErrorMessage());
    result.put("exitStatus", data.getExitStatus());
    result.put("institutionId", data.getInstitutionId());
    result.put("institutionName", data.getInstitutionName());
    result.put("institutionSearchQuery", data.getInstitutionSearchQuery());
    result.put("linkSessionId", data.getLinkSessionId());
    result.put("mfaType", data.getMfaType());
    result.put("requestId", data.getRequestId());
    result.put("timestamp", data.getTimestamp());
    result.put("viewName", data.getViewName() == null ? "" : data.getViewName().getJsonValue());
    result.put("metadataJson", data.getMetadataJson());

    return result;
  }

  private Map<String, Object> mapFromSuccessMetadata(LinkSuccessMetadata data) {
    Map<String, Object> result = new HashMap<>();

    Map<String, String> institution = new HashMap<>();
    institution.put("name", data.getInstitution() == null ? "" : data.getInstitution().getName());
    institution.put("id", data.getInstitution() == null ? "" : data.getInstitution().getId());

    result.put("institution", institution);
    result.put("linkSessionId", data.getLinkSessionId());
    result.put("metadataJson", data.getMetadataJson());

    ArrayList<Object> accounts = new ArrayList<>();

    for (LinkAccount a: data.getAccounts()) {
      Map<String, String> aux = new HashMap<>();
      aux.put("id", a.getId());
      aux.put("mask", a.getMask());
      aux.put("name", a.getName());
      aux.put("type", a.getSubtype() == null ? "" : a.getSubtype().getAccountType() == null ? "" : a.getSubtype().getAccountType().getJson());
      aux.put("subtype", a.getSubtype() == null ? "" : a.getSubtype().getJson());
      aux.put("verificationStatus", a.getVerificationStatus() == null ? "" : a.getVerificationStatus().getJson());
      accounts.add(aux);
    }

    result.put("accounts", accounts);

    return result;
  }

  private Map<String, Object> mapFromExitMetadata(LinkExitMetadata data) {
    Map<String, Object> result = new HashMap<>();

    Map<String, String> institution = new HashMap<>();
    institution.put("name", data.getInstitution() == null ? "" : data.getInstitution().getName());
    institution.put("id", data.getInstitution() == null ? "" : data.getInstitution().getId());

    result.put("institution", institution);
    result.put("requestId", data.getRequestId());
    result.put("linkSessionId", data.getLinkSessionId());
    result.put("status", data.getStatus() == null ? "" : data.getStatus().getJsonValue());
    result.put("metadataJson", data.getMetadataJson());

    return result;
  }
}

