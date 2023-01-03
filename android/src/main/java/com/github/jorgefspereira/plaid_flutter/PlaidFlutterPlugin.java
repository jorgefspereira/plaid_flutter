package com.github.jorgefspereira.plaid_flutter;

import android.app.Application;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

import androidx.annotation.NonNull;

import java.util.Map;
import java.util.HashMap;
import java.util.ArrayList;
import java.util.Objects;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.EventChannel.EventSink;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.ActivityResultListener;

import kotlin.Unit;

import com.plaid.link.Plaid;
import com.plaid.link.configuration.LinkPublicKeyConfiguration;
import com.plaid.link.configuration.LinkTokenConfiguration;
import com.plaid.link.configuration.PlaidEnvironment;
import com.plaid.link.configuration.PlaidProduct;
import com.plaid.link.event.LinkEventMetadata;
import com.plaid.link.result.LinkAccount;
import com.plaid.link.result.LinkAccountSubtype;
import com.plaid.link.result.LinkError;
import com.plaid.link.result.LinkExitMetadata;
import com.plaid.link.result.LinkSuccessMetadata;
import com.plaid.link.result.LinkResultHandler;

/** PlaidFlutterPlugin */
public class PlaidFlutterPlugin implements FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler, ActivityAware, ActivityResultListener {

  private static final String METHOD_CHANNEL_NAME = "plugins.flutter.io/plaid_flutter";
  private static final String EVENT_CHANNEL_NAME = "plugins.flutter.io/plaid_flutter/events";

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
  private static final String EVENT_ON_SUCCESS = "success";
  private static final String EVENT_ON_EXIT = "exit";
  private static final String EVENT_ON_EVENT = "event";
  private static final String KEY_ERROR = "error";
  private static final String KEY_METADATA = "metadata";
  private static final String KEY_PUBLIC_TOKEN = "publicToken";
  private static final String KEY_NAME = "name";
  private static final String KEY_TYPE = "type";

  // Prefix
  private static final String LINK_TOKEN_PREFIX = "link-";

  private ActivityPluginBinding binding;
  private Context context;
  private MethodChannel methodChannel;
  private EventChannel eventChannel;
  private EventSink eventSink;

  /// Result handler
  private final LinkResultHandler resultHandler = new LinkResultHandler(
      linkSuccess -> {
        Map<String, Object> data = new HashMap<>();

        data.put(KEY_TYPE, EVENT_ON_SUCCESS);
        data.put(KEY_PUBLIC_TOKEN, linkSuccess.getPublicToken());
        data.put(KEY_METADATA, mapFromSuccessMetadata(linkSuccess.getMetadata()));

        sendEvent(data);

        return Unit.INSTANCE;
      },
      linkExit -> {
        Map<String, Object> data = new HashMap<>();
        data.put(KEY_TYPE, EVENT_ON_EXIT);
        data.put(KEY_METADATA, mapFromExitMetadata(linkExit.getMetadata()));

        LinkError error = linkExit.getError();

        if(error != null) {
          data.put(KEY_ERROR, mapFromError(error));
        }

        sendEvent(data);
        return Unit.INSTANCE;
      }
  );

  /// FlutterPlugin

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    this.context = binding.getApplicationContext();
    this.methodChannel = new MethodChannel(binding.getBinaryMessenger(), METHOD_CHANNEL_NAME);
    this.methodChannel.setMethodCallHandler(this);
    this.eventChannel = new EventChannel(binding.getBinaryMessenger(), EVENT_CHANNEL_NAME);
    this.eventChannel.setStreamHandler(this);
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    this.context = null;
    this.methodChannel.setMethodCallHandler(null);
    this.methodChannel = null;
    this.eventChannel.setStreamHandler(null);
    this.eventChannel = null;
  }

  /// MethodCallHandler

  @Override
  public void onMethodCall(MethodCall call, @NonNull Result result) {
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
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    this.binding = binding;
    this.binding.addActivityResultListener(this);
  }

  @Override
  public void onDetachedFromActivity() {
    this.binding.removeActivityResultListener(this);
    this.binding = null;
  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
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

  /// EventChannel.StreamHandler

  @Override
  public void onListen(Object arguments, EventChannel.EventSink events) {
    eventSink = events;
  }

  @Override
  public void onCancel(Object arguments) {
    eventSink = null;
  }

  private void sendEvent(Object argument) {
    if (eventSink != null) {
      eventSink.success(argument);
    }
  }

  /// Exposed methods

  private void open(Map<String, Object> arguments) {
    if (binding == null) {
      Log.w("PlaidFlutterPlugin", "Activity not attached");
      throw new IllegalStateException("Activity not attached");
    }

    Plaid.setLinkEventListener(linkEvent -> {
      Map<String, Object> data = new HashMap<>();
      data.put(KEY_TYPE, EVENT_ON_EVENT);
      data.put(KEY_NAME, linkEvent.getEventName().toString());
      data.put(KEY_METADATA, mapFromEventMetadata(linkEvent.getMetadata()));

      sendEvent(data);
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
        LinkPublicKeyConfiguration config = getLegacyLinkConfiguration(arguments);
        Plaid.create((Application)context.getApplicationContext(), config).open(binding.getActivity());
        return;
      } catch (Exception e) {
        Log.w("PlaidFlutterPlugin", e.getMessage());
        throw e;
      }
    }

    LinkTokenConfiguration config = getLinkTokenConfiguration(arguments);

    if(config != null) {
      Plaid.create((Application)context.getApplicationContext(),config).open(binding.getActivity());
    }
  }

  private void close() {
    if (binding != null) {
      Intent intent = new Intent(context.getApplicationContext(), binding.getActivity().getClass());
      intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
      binding.getActivity().startActivity(intent);
    }
  }

  /// Configuration Parsing

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
    configuration.noLoadingState(false);

    if (arguments.containsKey(NO_LOADING_STATE)) {
      boolean state = (boolean) Objects.requireNonNull(arguments.get(NO_LOADING_STATE));
      configuration.noLoadingState(state);
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

  /// Metadata Parsing

  private Map<String, String> mapFromError(LinkError error) {
    Map<String, String> result = new HashMap<>();

    result.put("errorType", ""); //TODO:
    result.put("errorCode", error.getErrorCode().getJson());
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
      aux.put("type", a.getSubtype().getAccountType().getJson());
      aux.put("subtype", a.getSubtype().getJson());

      if (a.getVerificationStatus() != null) {
        aux.put("verificationStatus", a.getVerificationStatus().getJson());
      }

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

