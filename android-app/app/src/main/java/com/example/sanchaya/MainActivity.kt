package com.example.sanchaya

import android.annotation.SuppressLint
import android.os.Bundle
import android.webkit.WebChromeClient
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import androidx.compose.ui.viewinterop.AndroidView
import com.example.sanchaya.theme.SanchayaTheme

class MainActivity : ComponentActivity() {
  @SuppressLint("SetJavaScriptEnabled")
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)

    enableEdgeToEdge()
    setContent {
      SanchayaTheme {
        Surface(modifier = Modifier.fillMaxSize(), color = MaterialTheme.colorScheme.background) {
          AndroidView(
            factory = { context ->
              WebView(context).apply {
                settings.apply {
                  javaScriptEnabled = true
                  domStorageEnabled = true
                  mixedContentMode = WebSettings.MIXED_CONTENT_ALWAYS_ALLOW
                  cacheMode = WebSettings.LOAD_DEFAULT
                }
                webViewClient = WebViewClient()
                webChromeClient = WebChromeClient()
                
                // Use 10.0.2.2 for the Android emulator to access the host's localhost
                // Or change to your production URL when deploying
                loadUrl("http://10.0.2.2:3000")
              }
            },
            update = { webView ->
              // Nothing to update dynamically
            }
          )
        }
      }
    }
  }
}
