package com.sharablepiggy.app

import android.app.Activity
import android.content.ContentValues
import android.content.Intent
import android.os.Build
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pendingBytes: ByteArray? = null
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.sharablepiggy.app/qr")
            .setMethodCallHandler { call, result ->
                if (call.method != "saveQr") { result.notImplemented(); return@setMethodCallHandler }
                val bytes = call.arguments as? ByteArray
                if (bytes == null) { result.error("invalid_image", "Missing QR image", null); return@setMethodCallHandler }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    val values = ContentValues().apply {
                        put(MediaStore.Images.Media.DISPLAY_NAME, "Piggy-QR-${System.currentTimeMillis()}.png")
                        put(MediaStore.Images.Media.MIME_TYPE, "image/png")
                        put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/Piggy")
                        put(MediaStore.Images.Media.IS_PENDING, 1)
                    }
                    var uri: android.net.Uri? = null
                    try {
                        uri = contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
                            ?: error("Could not create image")
                        (contentResolver.openOutputStream(uri) ?: error("Could not open image")).use { it.write(bytes) }
                        values.clear()
                        values.put(MediaStore.Images.Media.IS_PENDING, 0)
                        contentResolver.update(uri, values, null, null)
                        result.success(null)
                    } catch (e: Exception) {
                        uri?.let { contentResolver.delete(it, null, null) }
                        result.error("save_failed", e.message, null)
                    }
                } else {
                    if (pendingResult != null) { result.error("busy", "Save already in progress", null); return@setMethodCallHandler }
                    pendingBytes = bytes
                    pendingResult = result
                    startActivityForResult(Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = "image/png"
                        putExtra(Intent.EXTRA_TITLE, "Piggy-QR.png")
                    }, 731)
                }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != 731) return
        val result = pendingResult ?: return
        try {
            val uri = data?.data
            if (resultCode != Activity.RESULT_OK || uri == null) {
                result.error("cancelled", "Save cancelled", null)
            } else {
                (contentResolver.openOutputStream(uri) ?: error("Could not open file")).use { it.write(pendingBytes!!) }
                result.success(null)
            }
        } catch (e: Exception) { result.error("save_failed", e.message, null) }
        finally { pendingBytes = null; pendingResult = null }
    }
}
