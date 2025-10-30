package com.github.jorgefspereira.plaid_flutter;

import android.app.Activity;
import android.app.Application;
import android.content.Context;
import android.view.View;
import android.widget.FrameLayout;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.util.Map;
import java.util.HashMap;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

import com.plaid.link.Plaid;
import com.plaid.link.PlaidHandler;
import com.plaid.link.configuration.LinkTokenConfiguration;
import com.plaid.link.result.LinkExit;
import com.plaid.link.result.LinkSuccess;

import kotlin.Unit;
import kotlin.jvm.functions.Function1;

// Factory class
public class PLKEmbeddedView extends PlatformViewFactory {

    private final BinaryMessenger messenger;
    private final PlaidFlutterPlugin plugin;

    public PLKEmbeddedView(@NonNull BinaryMessenger messenger, @NonNull PlaidFlutterPlugin plugin) {
        super(StandardMessageCodec.INSTANCE);
        this.messenger = messenger;
        this.plugin = plugin;
    }

    @Override
    public PlatformView create(Context context, int viewId, @Nullable Object args) {
        Map<String, Object> arguments = (Map<String, Object>) args;
        String token = (String) arguments.get("token");

        return new PLKEmbeddedPlatformView(context, plugin, token);
    }
}

// PlatformView implementation
class PLKEmbeddedPlatformView implements PlatformView {

    private final Context context;
    private final PlaidFlutterPlugin plugin;
    private FrameLayout containerView;

    PLKEmbeddedPlatformView(Context context, PlaidFlutterPlugin plugin, String token) {
        this.context = context;
        this.plugin = plugin;
        createEmbeddedView(token);
    }

    private void createEmbeddedView(String token) {
        containerView = new FrameLayout(context);
        containerView.setLayoutParams(new FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT
        ));

        Activity activity = plugin.getActivity();
        if (token != null && activity != null) {
            // Create LinkTokenConfiguration
            LinkTokenConfiguration config = new LinkTokenConfiguration.Builder()
                .token(token)
                .build();

            // Function to handle the full flow when user selects institution
            Function1<LinkTokenConfiguration, Unit> onSuccess = new Function1<LinkTokenConfiguration, Unit>() {
                @Override
                public Unit invoke(LinkTokenConfiguration newConfig) {
                    Application application = activity.getApplication();
                    PlaidHandler handler = Plaid.create(application, newConfig);
                    handler.open(activity);
                    return Unit.INSTANCE;
                }
            };

            // Create embedded view with callbacks
            View embeddedView = Plaid.createLinkEmbeddedView(
                activity,
                config,
                onSuccess,
                this::onExit
            );

            // Add the embedded view to our container
            containerView.addView(embeddedView);
        }
    }

    private Unit onExit(LinkExit linkExit) {
        Map<String, Object> data = new HashMap<>();
        data.put("type", "exit");
        data.put("metadata", plugin.mapFromExitMetadata(linkExit.getMetadata()));

        if (linkExit.getError() != null) {
            data.put("error", plugin.mapFromError(linkExit.getError()));
        }

        plugin.sendEvent(data);
        return Unit.INSTANCE;
    }

    @Override
    public View getView() {
        return containerView;
    }

    @Override
    public void dispose() {
        if (containerView != null) {
            containerView.removeAllViews();
            containerView = null;
        }
    }
}