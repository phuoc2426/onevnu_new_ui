package com.vnu.students

import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.util.Log
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val tag = "GmailSender"
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

                "sendToGmail" -> {
                    try {
                        val to = call.argument<String>("to") ?: ""
                        val subject = call.argument<String>("subject") ?: ""
                        val body = call.argument<String>("body") ?: ""
                        val paths = call.argument<List<*>>("attachmentPaths")
                            ?.mapNotNull { it as? String }
                            ?: emptyList()

                        Log.d(tag, "sendToGmail called")
                        Log.d(tag, "to=$to subject=$subject attachments=${paths.size}")

                        sendToGmail(to, subject, body, paths)
                        result.success(true)
                    } catch (e: ActivityNotFoundException) {
                        Log.e(tag, "No app can handle email intent", e)
                        result.error(
                            "EMAIL_APP_NOT_FOUND",
                            "No email app can handle this request.",
                            null
                        )
                    } catch (e: Exception) {
                        Log.e(tag, "Failed to open Gmail", e)
                        result.error(
                            "OPEN_GMAIL_FAILED",
                            e.message ?: "Cannot open Gmail.",
                            null
                        )
                    }
                }

                else -> result.notImplemented()
            }
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
        } catch (_: PackageManager.NameNotFoundException) {
            false
        }
    }

    private fun sendToGmail(
        to: String,
        subject: String,
        body: String,
        attachmentPaths: List<String>
    ) {
        Log.d(tag, "gmail installed=${isPackageInstalled(gmailPackage)}")

        val uris = ArrayList<Uri>()

        attachmentPaths.forEach { path ->
            val file = File(path)
            if (!file.exists()) {
                Log.w(tag, "attachment path does not exist: $path")
                return@forEach
            }

            val uri = FileProvider.getUriForFile(
                this,
                "${applicationContext.packageName}.gmail.fileprovider",
                file
            )
            uris.add(uri)
            grantUriPermission(gmailPackage, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
            Log.d(tag, "attachment uri=$uri")
        }

        val gmailIntent = buildEmailIntent(to, subject, body, uris).apply {
            setPackage(gmailPackage)
        }
        val gmailResolve = gmailIntent.resolveActivity(packageManager)
        Log.d(tag, "gmail intent=${gmailIntent.toUri(0)}")
        Log.d(tag, "gmail resolve=$gmailResolve")

        if (gmailResolve != null) {
            startActivity(gmailIntent)
            return
        }

        val fallbackIntent = buildEmailIntent(to, subject, body, uris)
        val fallbackResolve = fallbackIntent.resolveActivity(packageManager)
        Log.d(tag, "fallback intent=${fallbackIntent.toUri(0)}")
        Log.d(tag, "fallback resolve=$fallbackResolve")

        if (fallbackResolve == null) {
            throw ActivityNotFoundException("No email app can handle this intent")
        }

        startActivity(Intent.createChooser(fallbackIntent, "Send email"))
    }

    private fun buildEmailIntent(
        to: String,
        subject: String,
        body: String,
        uris: ArrayList<Uri>
    ): Intent {
        val intent = if (uris.size > 1) {
            Intent(Intent.ACTION_SEND_MULTIPLE).apply {
                putParcelableArrayListExtra(Intent.EXTRA_STREAM, uris)
            }
        } else {
            Intent(Intent.ACTION_SEND).apply {
                if (uris.size == 1) {
                    putExtra(Intent.EXTRA_STREAM, uris[0])
                }
            }
        }

        intent.type = if (uris.isNotEmpty()) "image/*" else "text/plain"
        intent.putExtra(Intent.EXTRA_EMAIL, arrayOf(to))
        intent.putExtra(Intent.EXTRA_SUBJECT, subject)
        intent.putExtra(Intent.EXTRA_TEXT, body)
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)

        if (uris.isNotEmpty()) {
            val clipData = ClipData.newUri(contentResolver, "attachment", uris.first())
            uris.drop(1).forEach { uri ->
                clipData.addItem(ClipData.Item(uri))
            }
            intent.clipData = clipData
        }

        return intent
    }
}
