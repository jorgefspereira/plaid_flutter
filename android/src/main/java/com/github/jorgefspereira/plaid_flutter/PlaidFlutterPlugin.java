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
import com.plaid.linkbase.models.configuration.LinkEventViewName;
import com.plaid.linkbase.models.configuration.PlaidEnvironment;
import com.plaid.linkbase.models.configuration.PlaidOptions;
import com.plaid.linkbase.models.configuration.PlaidProduct;
import com.plaid.linkbase.models.connection.LinkAccount;
import com.plaid.linkbase.models.connection.LinkCancellation;
import com.plaid.linkbase.models.connection.LinkConnection;
import com.plaid.linkbase.models.connection.LinkConnection.LinkConnectionMetadata;
import com.plaid.linkbase.models.connection.LinkExitMetadata;
import com.plaid.linkbase.models.connection.PlaidError;
import com.plaid.linkbase.models.connection.PlaidLinkResultHandler;
import com.plaid.linkbase.models.configuration.LinkConfiguration;
import com.plaid.linkbase.models.configuration.LinkEvent;
import com.plaid.linkbase.models.configuration.LinkEventMetadata;
import com.plaid.log.LogLevel;

import org.json.JSONObject;


/** PlaidFlutterPlugin */
public class PlaidFlutterPlugin implements MethodCallHandler, PluginRegistry.ActivityResultListener {

  private Activity activity;
  private MethodChannel channel;

  private static final String CHANNEL_NAME = "plugins.flutter.io/plaid_flutter";
  private static final int LINK_REQUEST_CODE = 1;

  private PlaidLinkResultHandler plaidLinkResultHandler = new PlaidLinkResultHandler(
      LINK_REQUEST_CODE,
      new Function1<LinkConnection, Unit>() {
        @Override
        public Unit invoke(LinkConnection e) {
          Map<String, Object> data = new HashMap<>();

          data.put("publicToken", e.getPublicToken());
          data.put("metadata", createMapFromConnectionMetadata(e.getLinkConnectionMetadata()));

          channel.invokeMethod("onAccountLinked", data);
          return Unit.INSTANCE;
        }
      },
      new Function1<LinkCancellation, Unit>() {
        @Override
        public Unit invoke(LinkCancellation e) {
          Map<String, Object> data = new HashMap<>();
          Map<String, String> metadata = new HashMap<>();

          metadata.put("institution_name", e.getInstitutionName());
          metadata.put("exit_status", e.getExitStatus());
          metadata.put("link_session_id", e.getLinkSessionId());
          metadata.put("institution_id", e.getInstitutionId());
          metadata.put("status", e.getStatus());

          data.put("metadata", metadata);

          channel.invokeMethod("onExit", data);
          return Unit.INSTANCE;
        }
      },
      new Function1<PlaidError, Unit>() {
        @Override
        public Unit invoke(PlaidError e) {
          Map<String, Object> data = new HashMap<>();

          data.put("error", e.getErrorMessage());
          data.put("metadata", createMapFromExitMetadata(e.getLinkExitMetadata()));

          channel.invokeMethod("onAccountLinkError", data);
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

    PlaidOptions options = new PlaidOptions.Builder()
            .logLevel(BuildConfig.DEBUG ? LogLevel.DEBUG : LogLevel.ASSERT)
            .build();

    Plaid.setOptions(options);
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    if (call.method.equals("open")) {

      Map<String, Object> arguments = call.arguments();

      String clientName = (String) arguments.get("clientName");
      String publicKey = (String)arguments.get("publicKey");
      String envString = (String)arguments.get("env");
      PlaidEnvironment env = PlaidEnvironment.valueOf(envString.toUpperCase());

      String userLegalName = (String) arguments.get("userLegalName");
      String userEmailAddress = (String) arguments.get("userEmailAddress");
      String userPhoneNumber = (String) arguments.get("userPhoneNumber");

      String language = (String) arguments.get("language");
      String linkCustomizationName = (String) arguments.get("linkCustomizationName");
      String webhook = (String) arguments.get("webhook");
      ArrayList<String> countryCodes = (ArrayList<String>) arguments.get("countryCodes");

      //NOTE: Not supported like plaid ios sdk
      // String oauthNonce = (String) arguments.get("oauthNonce");
      // String oauthRedirectUri = (String) arguments.get("oauthRedirectUri");

      ArrayList<PlaidProduct> products = new ArrayList<>();
      ArrayList<?> productsObjects = (ArrayList<?>)arguments.get("products");

      for (Object po : productsObjects) {
        String ps = (String)po;
        PlaidProduct p = PlaidProduct.valueOf(ps.toUpperCase());
        products.add(p);
      }

      LinkConfiguration.Builder configuration = new LinkConfiguration.Builder(clientName, products).environment(env);

      if(userLegalName != null) {
        configuration.userLegalName(userLegalName);
      }

      if(userEmailAddress != null) {
        configuration.userEmailAddress(userEmailAddress);
      }

      if(userPhoneNumber != null) {
        configuration.userPhoneNumber(userPhoneNumber);
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

      Map<String, String> extraParams = new HashMap<>();
      Map<String, ArrayList<String>> accountSubtypes = (Map<String, ArrayList<String>>) arguments.get("accountSubtypes");

      if(accountSubtypes != null) {
        JSONObject json = new JSONObject(accountSubtypes);
        extraParams.put("accountSubtypes", json.toString());
        configuration.extraParams(extraParams);
      }

      Plaid.setPublicKey(publicKey);
      Plaid.setLinkEventListener(new Function1<LinkEvent, Unit>() {
                                   @Override
                                   public Unit invoke(LinkEvent e) {
                                     Map<String, Object> data = new HashMap<>();
                                     data.put("event", e.getEventName());
                                     data.put("metadata", createMapFromEventMetadata(e.getMetadata()));

                                     channel.invokeMethod("onEvent", data);
                                     return Unit.INSTANCE;
                                   }
                                 });

      Plaid.openLink(activity, configuration.build(), LINK_REQUEST_CODE);

    } else {
      result.notImplemented();
    }
  }

  @Override
  public boolean onActivityResult(int requestCode, int resultCode, Intent intent) {
    return plaidLinkResultHandler.onActivityResult(requestCode, resultCode, intent);
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

    String viewName = data.getViewName().toString();
    String trimViewName = viewName.substring(viewName.lastIndexOf("(") + 1, viewName.lastIndexOf(")"));

    result.put("view_name", trimViewName);
    result.put("error_type", data.getErrorType());

    return result;
  }

  private Map<String, Object> createMapFromConnectionMetadata(LinkConnectionMetadata data) {
    Map<String, Object> result = new HashMap<>();

    result.put("institution_name", data.getInstitutionName());
    result.put("link_session_id", data.getLinkSessionId());
    result.put("institution_id", data.getInstitutionId());

    ArrayList<Object> accounts = new ArrayList<>();

    for (LinkAccount a: data.getAccounts()) {
      Map<String, String> aux = new HashMap<>();
      aux.put("id", a.getAccountId());
      aux.put("mask", a.getAccountNumber());
      aux.put("name", a.getAccountName());
      aux.put("type", a.getAccountType());
      aux.put("subtype", a.getAccountSubType());
      accounts.add(aux);
    }

    result.put("accounts", accounts);
    result.put("account", accounts.get(0));

    return result;
  }

  private Map<String, String> createMapFromExitMetadata(LinkExitMetadata data) {
    Map<String, String> result = new HashMap<>();

    result.put("institution_name", data.getInstitutionName());
    result.put("request_id", data.getRequestId());
    result.put("link_session_id", data.getLinkSessionId());
    result.put("institution_id", data.getInstitutionId());
    result.put("status", data.getStatus());

    return result;
  }
}

