package com.example.aiaprtd_member

import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.aiaprtd.whatsapp_share"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "sharePdf") {
                val phone = call.argument<String>("phone")
                val filePath = call.argument<String>("filePath")
                if (phone != null && filePath != null) {
                    val file = File(filePath)
                    if (!file.exists()) {
                        result.error("FILE_NOT_FOUND", "File does not exist: $filePath", null)
                        return@setMethodCallHandler
                    }

                    val uri: Uri = FileProvider.getUriForFile(applicationContext, "${applicationContext.packageName}.fileprovider", file)
                    
                    val intent = Intent(Intent.ACTION_SEND)
                    intent.type = "application/pdf"
                    intent.putExtra(Intent.EXTRA_STREAM, uri)
                    
                    // Format phone number to JID
                    var formattedPhone = phone
                    if (formattedPhone.startsWith("+")) {
                        formattedPhone = formattedPhone.substring(1)
                    }
                    if (formattedPhone.startsWith("0")) {
                        formattedPhone = "94" + formattedPhone.substring(1) // Assuming Sri Lanka
                    }
                    intent.putExtra("jid", "$formattedPhone@s.whatsapp.net")
                    intent.setPackage("com.whatsapp")
                    intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)

                    try {
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("UNAVAILABLE", "WhatsApp not installed or error: ${e.message}", null)
                    }
                } else {
                    result.error("INVALID_ARGS", "Phone or File Path is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
