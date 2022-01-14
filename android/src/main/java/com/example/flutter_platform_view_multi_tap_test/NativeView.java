package com.example.flutter_platform_view_multi_tap_test;

import android.content.Context;
import android.graphics.Color;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.flutter.plugin.platform.PlatformView;
import java.util.Map;

class NativeView implements PlatformView {
   @NonNull private final LayoutInflater li;
   @NonNull private final View contentMainView;

    NativeView(@NonNull Context context, int id, @Nullable Map<String, Object> creationParams) {
        li = LayoutInflater.from(context);
        contentMainView = li.inflate(R.layout.content_main, null);
    }

    @NonNull
    @Override
    public View getView() {
        return contentMainView;
    }

    @Override
    public void dispose() {}
}
