//package com.vnu.students
//
//import android.content.ActivityNotFoundException
//import android.content.ClipData
//import android.content.Intent
//import android.content.pm.PackageManager
//import android.net.Uri
//import android.os.Build
//import android.util.Log
//import androidx.core.content.FileProvider
//import io.flutter.embedding.android.FlutterActivity
//import io.flutter.embedding.engine.FlutterEngine
//import io.flutter.plugin.common.MethodChannel
//import java.io.File
//
//class MainActivity : FlutterActivity() {
//    private val tag = "GmailSender"
//    private val channelName = "gmail_sender"
//    private val gmailPackage = "com.google.android.gm"
//
//    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
//        super.configureFlutterEngine(flutterEngine)
//
//        MethodChannel(
//            flutterEngine.dartExecutor.binaryMessenger,
//            channelName
//        ).setMethodCallHandler { call, result ->
//            when (call.method) {
//                "isGmailInstalled" -> {
//                    result.success(isPackageInstalled(gmailPackage))
//                }
//
//                "sendToGmail" -> {
//                    try {
//                        val to = call.argument<String>("to") ?: ""
//                        val subject = call.argument<String>("subject") ?: ""
//                        val body = call.argument<String>("body") ?: ""
//                        val paths = call.argument<List<*>>("attachmentPaths")
//                            ?.mapNotNull { it as? String }
//                            ?: emptyList()
//
//                        Log.d(tag, "sendToGmail called")
//                        Log.d(tag, "to=$to subject=$subject attachments=${paths.size}")
//
//                        sendToGmail(to, subject, body, paths)
//                        result.success(true)
//                    } catch (e: ActivityNotFoundException) {
//                        Log.e(tag, "No app can handle email intent", e)
//                        result.error(
//                            "EMAIL_APP_NOT_FOUND",
//                            "No email app can handle this request.",
//                            null
//                        )
//                    } catch (e: Exception) {
//                        Log.e(tag, "Failed to open Gmail", e)
//                        result.error(
//                            "OPEN_GMAIL_FAILED",
//                            e.message ?: "Cannot open Gmail.",
//                            null
//                        )
//                    }
//                }
//
//                else -> result.notImplemented()
//            }
//        }
//    }
//
//    private fun isPackageInstalled(packageName: String): Boolean {
//        return try {
//            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
//                packageManager.getPackageInfo(
//                    packageName,
//                    PackageManager.PackageInfoFlags.of(0)
//                )
//            } else {
//                @Suppress("DEPRECATION")
//                packageManager.getPackageInfo(packageName, 0)
//            }
//            true
//        } catch (_: PackageManager.NameNotFoundException) {
//            false
//        }
//    }
//
//    private fun sendToGmail(
//        to: String,
//        subject: String,
//        body: String,
//        attachmentPaths: List<String>
//    ) {
//        Log.d(tag, "gmail installed=${isPackageInstalled(gmailPackage)}")
//
//        val uris = ArrayList<Uri>()
//
//        attachmentPaths.forEach { path ->
//            val file = File(path)
//            if (!file.exists()) {
//                Log.w(tag, "attachment path does not exist: $path")
//                return@forEach
//            }
//
//            val uri = FileProvider.getUriForFile(
//                this,
//                "${applicationContext.packageName}.gmail.fileprovider",
//                file
//            )
//            uris.add(uri)
//            grantUriPermission(gmailPackage, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
//            Log.d(tag, "attachment uri=$uri")
//        }
//
//        val gmailIntent = buildEmailIntent(to, subject, body, uris).apply {
//            setPackage(gmailPackage)
//        }
//        val gmailResolve = gmailIntent.resolveActivity(packageManager)
//        Log.d(tag, "gmail intent=${gmailIntent.toUri(0)}")
//        Log.d(tag, "gmail resolve=$gmailResolve")
//
//        if (gmailResolve != null) {
//            startActivity(gmailIntent)
//            return
//        }
//
//        val fallbackIntent = buildEmailIntent(to, subject, body, uris)
//        val fallbackResolve = fallbackIntent.resolveActivity(packageManager)
//        Log.d(tag, "fallback intent=${fallbackIntent.toUri(0)}")
//        Log.d(tag, "fallback resolve=$fallbackResolve")
//
//        if (fallbackResolve == null) {
//            throw ActivityNotFoundException("No email app can handle this intent")
//        }
//
//        startActivity(Intent.createChooser(fallbackIntent, "Send email"))
//    }
//
//    private fun buildEmailIntent(
//        to: String,
//        subject: String,
//        body: String,
//        uris: ArrayList<Uri>
//    ): Intent {
//        val intent = if (uris.size > 1) {
//            Intent(Intent.ACTION_SEND_MULTIPLE).apply {
//                putParcelableArrayListExtra(Intent.EXTRA_STREAM, uris)
//            }
//        } else {
//            Intent(Intent.ACTION_SEND).apply {
//                if (uris.size == 1) {
//                    putExtra(Intent.EXTRA_STREAM, uris[0])
//                }
//            }
//        }
//
//        intent.type = if (uris.isNotEmpty()) "image/*" else "text/plain"
//        intent.putExtra(Intent.EXTRA_EMAIL, arrayOf(to))
//        intent.putExtra(Intent.EXTRA_SUBJECT, subject)
//        intent.putExtra(Intent.EXTRA_TEXT, body)
//        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
//
//        if (uris.isNotEmpty()) {
//            val clipData = ClipData.newUri(contentResolver, "attachment", uris.first())
//            uris.drop(1).forEach { uri ->
//                clipData.addItem(ClipData.Item(uri))
//            }
//            intent.clipData = clipData
//        }
//
//        return intent
//    }
//}

//ORIGIN
//package com.vnu.students
//
//import io.flutter.embedding.android.FlutterActivity
//import io.flutter.embedding.android.FlutterFragmentActivity
//
//class MainActivity: FlutterFragmentActivity() {
//}


package  com.vnu.students

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterFragmentActivity() {
    private val channelName = "gmail_sender"
    private val gmailPackage = "com.google.android.gm"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isGmailInstalled" -> {
                    result.success(isPackageInstalled(gmailPackage))
                }

                "getCapabilities" -> {
                    result.success(
                        mapOf(
                            "platform" to "android",
                            "gmailInstalled" to isPackageInstalled(gmailPackage),
                            "canUseNativeMail" to false,
                            "canUseShareFallback" to false,
                            "gmailOnly" to true,
                            "supportsAttachmentWithGmail" to true,
                            "message" to if (isPackageInstalled(gmailPackage)) {
                                "Thiết bị đã cài Gmail."
                            } else {
                                "Thiết bị chưa cài Gmail."
                            }
                        )
                    )
                }

                "composeEmail" -> {
                    composeEmail(call, result)
                }

                "openInstallGmail" -> {
                    openInstallGmail(result)
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun composeEmail(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        if (!isPackageInstalled(gmailPackage)) {
            result.success(
                mapOf(
                    "success" to false,
                    "mode" to "android_gmail_not_installed",
                    "message" to "Thiết bị chưa cài Gmail. Vui lòng cài Gmail của Google để gửi yêu cầu."
                )
            )
            return
        }

        val args = call.arguments as? Map<*, *> ?: emptyMap<Any, Any>()

        val to = (args["to"] as? String)?.trim().orEmpty()
        val recipients = ((args["recipients"] as? List<*>)
            ?.mapNotNull { it?.toString()?.trim() }
            ?.filter { it.isNotEmpty() }
            ?: emptyList())
            .ifEmpty {
                if (to.isNotEmpty()) listOf(to) else emptyList()
            }

        val subject = args["subject"]?.toString()?.trim().orEmpty()
        val body = args["body"]?.toString()?.trim().orEmpty()

        val attachments = extractStringList(args, "attachments")
            .ifEmpty {
                extractStringList(args, "attachmentPaths")
            }
            .filter { it.trim().isNotEmpty() }

        try {
            val uris = attachments.mapNotNull { path ->
                val file = File(path)
                if (!file.exists()) {
                    null
                } else {
                    FileProvider.getUriForFile(
                        this,
                        "${applicationContext.packageName}.gmail_fileprovider",
                        file
                    )
                }
            }

            val intent = if (uris.size > 1) {
                Intent(Intent.ACTION_SEND_MULTIPLE)
            } else {
                Intent(Intent.ACTION_SEND)
            }

            intent.setPackage(gmailPackage)
            intent.type = if (uris.isEmpty()) "message/rfc822" else "image/*"

            if (recipients.isNotEmpty()) {
                intent.putExtra(Intent.EXTRA_EMAIL, recipients.toTypedArray())
            }

            intent.putExtra(Intent.EXTRA_SUBJECT, subject)
            intent.putExtra(Intent.EXTRA_TEXT, body)

            if (uris.size == 1) {
                intent.putExtra(Intent.EXTRA_STREAM, uris.first())
                intent.clipData = ClipData.newUri(
                    contentResolver,
                    "attachment",
                    uris.first()
                )
            } else if (uris.size > 1) {
                intent.putParcelableArrayListExtra(
                    Intent.EXTRA_STREAM,
                    ArrayList<Uri>(uris)
                )

                val clipData = ClipData.newUri(
                    contentResolver,
                    "attachment",
                    uris.first()
                )

                uris.drop(1).forEach { uri ->
                    clipData.addItem(ClipData.Item(uri))
                }

                intent.clipData = clipData
            }

            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)

            uris.forEach { uri ->
                grantUriPermission(
                    gmailPackage,
                    uri,
                    Intent.FLAG_GRANT_READ_URI_PERMISSION
                )
            }

            startActivity(intent)

            result.success(
                mapOf(
                    "success" to true,
                    "mode" to "android_opened_gmail",
                    "message" to "Đã mở Gmail. Vui lòng kiểm tra nội dung và bấm Gửi."
                )
            )
        } catch (e: ActivityNotFoundException) {
            result.success(
                mapOf(
                    "success" to false,
                    "mode" to "android_activity_not_found",
                    "message" to "Không mở được Gmail trên thiết bị này."
                )
            )
        } catch (e: Exception) {
            result.success(
                mapOf(
                    "success" to false,
                    "mode" to "android_open_gmail_failed",
                    "message" to "Không mở được Gmail: ${e.message ?: "Không rõ lỗi"}"
                )
            )
        }
    }

    private fun extractStringList(args: Map<*, *>, key: String): List<String> {
        val raw = args[key] ?: return emptyList()

        return when (raw) {
            is List<*> -> raw.mapNotNull { it?.toString() }
            is Array<*> -> raw.mapNotNull { it?.toString() }
            is String -> if (raw.trim().isNotEmpty()) listOf(raw) else emptyList()
            else -> emptyList()
        }
    }

    private fun isPackageInstalled(packageName: String): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                packageManager.getPackageInfo(
                    packageName,
                    PackageManager.PackageInfoFlags.of(0)
                )
            } else {
                @Suppress("DEPRECATION")
                packageManager.getPackageInfo(packageName, 0)
            }
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun openInstallGmail(result: MethodChannel.Result) {
        try {
            val marketIntent = Intent(
                Intent.ACTION_VIEW,
                Uri.parse("market://details?id=$gmailPackage")
            )
            startActivity(marketIntent)

            result.success(
                mapOf(
                    "success" to true,
                    "mode" to "android_opened_play_store",
                    "message" to "Đã mở trang cài Gmail."
                )
            )
        } catch (_: Exception) {
            try {
                val webIntent = Intent(
                    Intent.ACTION_VIEW,
                    Uri.parse("https://play.google.com/store/apps/details?id=$gmailPackage")
                )
                startActivity(webIntent)

                result.success(
                    mapOf(
                        "success" to true,
                        "mode" to "android_opened_gmail_store_web",
                        "message" to "Đã mở trang cài Gmail."
                    )
                )
            } catch (e: Exception) {
                result.success(
                    mapOf(
                        "success" to false,
                        "mode" to "android_open_store_failed",
                        "message" to "Không mở được trang cài Gmail: ${e.message ?: "Không rõ lỗi"}"
                    )
                )
            }
        }
    }
}