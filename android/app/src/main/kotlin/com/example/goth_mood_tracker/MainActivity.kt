package com.example.goth_mood_tracker   // <-- keep this as-is, matches your manifest

import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "goth_mood/ig_share"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isInstagramInstalled" -> {
                        result.success(isPackageInstalled("com.instagram.android"))
                    }
                    "shareToStories" -> {
                        val imagePath = call.argument<String>("imagePath")
                        val attributionURL = call.argument<String>("attributionURL")
                        if (imagePath.isNullOrEmpty()) {
                            result.error("NO_PATH", "imagePath is null/empty", null)
                            return@setMethodCallHandler
                        }
                        val file = File(imagePath)
                        val uri: Uri = FileProvider.getUriForFile(
                            this,
                            "${applicationContext.packageName}.fileprovider",
                            file
                        )
                        val intent = Intent("com.instagram.share.ADD_TO_STORY").apply {
                            setDataAndType(uri, "image/*")
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            putExtra("interactive_asset_uri", uri)
                            if (!attributionURL.isNullOrEmpty()) {
                                putExtra("content_url", attributionURL)
                            }
                        }
                        if (intent.resolveActivity(packageManager) != null) {
                            grantUriPermission(
                                "com.instagram.android",
                                uri,
                                Intent.FLAG_GRANT_READ_URI_PERMISSION
                            )
                            startActivity(intent)
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun isPackageInstalled(pkg: String): Boolean {
        return try {
            packageManager.getPackageInfo(pkg, 0)
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }
}

