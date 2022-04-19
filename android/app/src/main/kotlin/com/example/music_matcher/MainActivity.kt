package com.example.music_matcher

import android.content.Intent
import android.util.Log
import androidx.annotation.NonNull
import com.apple.android.sdk.authentication.AuthenticationFactory
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "apple-music.musicmatcher/auth"
    private val developerToken = "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IkoyOTNXWUQ3WVEifQ.eyJpYXQiOjE2NDkyOTIxMDcsImV4cCI6MTY2NDg0NDEwNywiaXNzIjoiM0haVlpHTVNONSJ9.T37bFWgg9gph3zEQF1qgEf7I83wws13-V8ZRQbtzj4nMLylyFH321rbAgk9BAc8E88jiimYn37DJtsaIiN19jg"
    private var authenticationManager = AuthenticationFactory.createAuthenticationManager(this)
    private var userToken = ""
    private var tokenSet = false

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "appleMusicAuth") {
                // Apple Music Authentication
                    Log.d("Auth", "Before intent")
                val intent = authenticationManager.createIntentBuilder(developerToken)
                        //.setHideStartScreen(true)
                        .setStartScreenMessage("Connecting to Apple Music")
                        .build()
                Log.d("Auth", "Intent built")
                startActivityForResult(intent, 1)

                //Thread waiting = new Thread()
                //result.success(authenticationManager.handleTokenResult(startActivityForResult(intent, 1)))

                //result.success(userToken)

            } else {
                result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        Log.d("On activity Result", "Starting result")
        if (requestCode == 1) {
            val result = authenticationManager.handleTokenResult(data)
            Log.d("On Activty Result","token acquired")

            if (result.isError) {
                val error = result.error
            }
            else {
                setResult(resultCode, data)
                //tokenSet = true
            }
        }
        else {
            Log.d("On Activity Result", "Not login code")
            super.onActivityResult(requestCode, resultCode, data)
        }
    }
}
