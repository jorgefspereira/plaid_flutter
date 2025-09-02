package com.github.jorgefspereira.plaid_flutter;

import android.app.Application;
import android.content.Context;
import android.content.Intent;

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
import com.plaid.link.PlaidHandler;
import com.plaid.link.SubmissionData;
import com.plaid.link.configuration.LinkTokenConfiguration;
import com.plaid.link.event.LinkEventMetadata;
import com.plaid.link.result.LinkAccount;
import com.plaid.link.result.LinkError;
import com.plaid.link.result.LinkExitMetadata;
import com.plaid.link.result.LinkSuccessMetadata;
import com.plaid.link.result.LinkResultHandler;

/** PlaidFlutterPlugin */
public class PlaidFlutterPlugin implements FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler, ActivityAware, ActivityResultListener {

  private static final String METHOD_CHANNEL_NAME = "plugins.flutter.io/plaid_flutter";
  private static final String EVENT_CHANNEL_NAME = "plugins.flutter.io/plaid_flutter/events";

  /// LinkTokenConfiguration
  private static final String TOKEN = "token";
  private static final String NO_LOADING_STATE = "noLoadingState";

  /// SubmissionData
  private static final String PHONE_NUMBER = "phoneNumber";
  private static final String DATE_OF_BIRTH = "dateOfBirth";

  /// LinkResultHandler
  private static final String EVENT_ON_SUCCESS = "success";
  private static final String EVENT_ON_EXIT = "exit";
  private static final String EVENT_ON_EVENT = "event";
  private static final String KEY_ERROR = "error";
  private static final String KEY_METADATA = "metadata";
  private static final String KEY_PUBLIC_TOKEN = "publicToken";
  private static final String KEY_NAME = "name";
  private static final String KEY_TYPE = "type";

  private ActivityPluginBinding binding;
  private Context context;
  private MethodChannel methodChannel;
  private EventChannel eventChannel;
  private EventSink eventSink;
  private PlaidHandler plaidHandler;

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
      switch (call.method) {
          case "create":
              this.create(call.arguments(), result);
              break;
          case "open":
              this.open(result);
              break;
          case "close":
              this.close(result);
              break;
          case "submit":
              this.submit(call.arguments(), result);
              break;
          default:
              result.notImplemented();
              break;
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

  private void create(Map<String, Object> arguments, Result reply) {
    if (binding == null) {
      reply.error("PlaidFlutter", "Activity not attached", null);
      return;
    }

    Plaid.setLinkEventListener(linkEvent -> {
      Map<String, Object> data = new HashMap<>();
      data.put(KEY_TYPE, EVENT_ON_EVENT);
      data.put(KEY_NAME, linkEvent.getEventName().toString());
      data.put(KEY_METADATA, mapFromEventMetadata(linkEvent.getMetadata()));

      sendEvent(data);
      return Unit.INSTANCE;
    });

    LinkTokenConfiguration config = getLinkTokenConfiguration(arguments);

    if(config != null) {
      plaidHandler = Plaid.create((Application)context.getApplicationContext(),config);
    }

    reply.success(null);
  }

  private void open(Result reply) {
    if (plaidHandler != null) {
      plaidHandler.open(binding.getActivity());
    }

    reply.success(null);
  }

  private void close(Result reply) {
    if (binding != null) {
      Intent intent = new Intent(context.getApplicationContext(), binding.getActivity().getClass());
      intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
      binding.getActivity().startActivity(intent);
    }

    reply.success(null);
  }

  private void submit(Map<String, Object> arguments, Result reply) {
    if (arguments == null) {
      reply.success(null);
      return;
    }

    Object pnObj = arguments.get(PHONE_NUMBER);
    String phoneNumber = pnObj instanceof String ? (String) pnObj : null;

    Object dobObj = arguments.get(DATE_OF_BIRTH);
    String dateOfBirth = dobObj instanceof String ? (String) dobObj : null;

    if (plaidHandler != null) {
      SubmissionData submissionData = new SubmissionData(phoneNumber, dateOfBirth);
      plaidHandler.submit(submissionData);
    }

    reply.success(null);
  }

  /// Configuration Parsing

  private LinkTokenConfiguration getLinkTokenConfiguration(Map<String, Object> arguments) {
    String token = (String) arguments.get(TOKEN);

    if (token == null) {
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
    result.put("accountNumberMask", data.getAccountNumberMask());
    result.put("isUpdateMode", data.isUpdateMode());
    result.put("matchReason", data.getMatchReason());
    result.put("routingNumber", data.getRoutingNumber());
    result.put("selection", data.getSelection());

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

