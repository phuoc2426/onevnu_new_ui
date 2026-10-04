package com.vnu.students

import android.annotation.SuppressLint
import android.net.http.SslError
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.view.ViewGroup
import android.webkit.SslErrorHandler
import android.webkit.WebResourceError
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebView
import android.webkit.WebViewClient
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.net.HttpURLConnection
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.URL
import java.security.KeyStore
import java.security.cert.CertificateException
import java.security.cert.X509Certificate
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import javax.net.ssl.HttpsURLConnection
import javax.net.ssl.SNIHostName
import javax.net.ssl.SSLContext
import javax.net.ssl.SSLHandshakeException
import javax.net.ssl.SSLParameters
import javax.net.ssl.TrustManagerFactory
import javax.net.ssl.X509TrustManager
import javax.net.ssl.SSLSocket

/**
 * Test-only diagnostics bridge.
 *
 * IMPORTANT:
 * - Uses Android's default trust store and default hostname verification.
 * - Never installs a permissive TrustManager.
 * - Never calls proceed() for WebView SSL errors.
 * - Does not log credentials, cookies, tokens, authorization codes or request bodies.
 *
 * This can expose the TLS/HTTP errors visible to the OneVNU process and Android WebView.
 * It cannot read Chrome Custom Tab's private Chromium logs. For that last layer, adb logcat
 * remains the authoritative source.
 */
object NetworkDiagnosticBridge {
    private const val METHOD_CHANNEL = "onevnu/network_diagnostic"
    private const val EVENT_CHANNEL = "onevnu/network_diagnostic_events"
    private const val TIMEOUT_MS = 10_000

    @Volatile
    private var eventSink: EventChannel.EventSink? = null

    private val executor = Executors.newSingleThreadExecutor()
    private val running = AtomicBoolean(false)
    private val mainHandler = Handler(Looper.getMainLooper())

    fun register(activity: FlutterFragmentActivity, flutterEngine: FlutterEngine) {
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            EVENT_CHANNEL
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            METHOD_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getDeviceInfo" -> result.success(getDeviceInfo(activity))
                "inspectTrustStore" -> {
                    executor.execute {
                        try {
                            val data = inspectTrustStore()
                            activity.runOnUiThread { result.success(data) }
                        } catch (t: Throwable) {
                            activity.runOnUiThread {
                                result.success(
                                    mapOf(
                                        "success" to false,
                                        "error" to throwableChain(t)
                                    )
                                )
                            }
                        }
                    }
                }
                "runDiagnostics" -> startDiagnostics(activity, call, result)
                "stopDiagnostics" -> {
                    running.set(false)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startDiagnostics(
        activity: FlutterFragmentActivity,
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        if (!running.compareAndSet(false, true)) {
            result.success(
                mapOf(
                    "started" to false,
                    "reason" to "already_running"
                )
            )
            return
        }

        val rawUrls = call.argument<List<*>>("urls")
            ?.mapNotNull { it?.toString()?.trim() }
            ?.filter { it.isNotEmpty() }
            ?.distinct()
            ?: emptyList()

        if (rawUrls.isEmpty()) {
            running.set(false)
            result.success(mapOf("started" to false, "reason" to "no_urls"))
            return
        }

        result.success(mapOf("started" to true, "count" to rawUrls.size))

        executor.execute {
            emit("RUN", "BEGIN", "INFO", "Bắt đầu chẩn đoán ${rawUrls.size} URL")

            try {
                val trust = inspectTrustStore()
                val r46 = trust["globalSignRootR46Present"] == true
                val r3 = trust["globalSignRootR3Present"] == true
                val r6 = trust["globalSignRootR6Present"] == true
                emit(
                    "TRUST_STORE",
                    "RESULT",
                    if (r46) "OK" else "WARN",
                    "AndroidCAStore: Root R46=${yesNo(r46)}, Root R3=${yesNo(r3)}, Root R6=${yesNo(r6)}",
                    trust
                )
            } catch (t: Throwable) {
                emit("TRUST_STORE", "FAILED", "ERROR", throwableChain(t))
            }

            for (urlText in rawUrls) {
                if (!running.get()) break

                val url = try {
                    URL(urlText)
                } catch (t: Throwable) {
                    emit("URL", "INVALID", "ERROR", "URL không hợp lệ: ${safeText(urlText)}")
                    continue
                }

                val safe = safeUrl(url)
                val host = url.host
                val port = if (url.port > 0) url.port else 443

                emit("TARGET", "BEGIN", "INFO", safe)
                probeDns(host)
                if (!running.get()) break
                probeTls(host, port)
                if (!running.get()) break
                probeHttps(url)
                if (!running.get()) break
                probeWebViewBlocking(activity, url)
                emit("TARGET", "END", "INFO", safe)
            }

            running.set(false)
            emit("RUN", "FINISHED", "INFO", "Đã hoàn tất chẩn đoán")
        }
    }

    private fun probeDns(host: String) {
        emit("DNS", "BEGIN", "INFO", host)
        try {
            val addresses = InetAddress.getAllByName(host)
                .mapNotNull { it.hostAddress }
                .distinct()
            emit(
                "DNS",
                "OK",
                "OK",
                if (addresses.isEmpty()) "Không có địa chỉ" else addresses.joinToString(", ")
            )
        } catch (t: Throwable) {
            emit("DNS", "FAILED", "ERROR", throwableChain(t))
        }
    }

    private fun probeTls(host: String, port: Int) {
        emit("NATIVE_TLS", "BEGIN", "INFO", "$host:$port")

        var socket: SSLSocket? = null
        var capturingTrustManager: CapturingTrustManager? = null
        var enabledProtocols: List<String> = emptyList()
        var enabledCipherSuites: List<String> = emptyList()
        try {
            val trustManagerFactory = TrustManagerFactory.getInstance(
                TrustManagerFactory.getDefaultAlgorithm()
            )
            trustManagerFactory.init(null as KeyStore?)
            val platformTrustManager = trustManagerFactory.trustManagers
                .filterIsInstance<X509TrustManager>()
                .firstOrNull()
                ?: throw IllegalStateException("Không tìm thấy X509TrustManager mặc định của Android")

            val trustManager = CapturingTrustManager(platformTrustManager)
            capturingTrustManager = trustManager

            val sslContext = SSLContext.getInstance("TLS")
            // The wrapper delegates validation to Android's default X509TrustManager.
            // It only records the presented chain/error; it never converts a failure to success.
            sslContext.init(null, arrayOf(trustManager), null)

            socket = sslContext.socketFactory.createSocket() as SSLSocket
            socket.soTimeout = TIMEOUT_MS
            socket.connect(InetSocketAddress(host, port), TIMEOUT_MS)

            val params: SSLParameters = socket.sslParameters
            params.endpointIdentificationAlgorithm = "HTTPS"
            params.serverNames = listOf(SNIHostName(host))
            socket.sslParameters = params
            enabledProtocols = socket.enabledProtocols.toList()
            enabledCipherSuites = socket.enabledCipherSuites.toList()

            socket.startHandshake()

            val session = socket.session
            val certs = session.peerCertificates
                .filterIsInstance<X509Certificate>()
                .mapIndexed { index, cert -> certSummary(index, cert) }

            emit(
                "NATIVE_TLS",
                "OK",
                "OK",
                "protocol=${session.protocol}; cipher=${session.cipherSuite}; peer=${session.peerHost}",
                mapOf(
                    "host" to host,
                    "protocol" to session.protocol,
                    "cipher" to session.cipherSuite,
                    "peerHost" to session.peerHost,
                    "peerPort" to session.peerPort,
                    "enabledProtocols" to enabledProtocols,
                    "enabledCipherSuites" to enabledCipherSuites,
                    "certificates" to certs
                )
            )
        } catch (t: SSLHandshakeException) {
            emit(
                "NATIVE_TLS",
                "HANDSHAKE_FAILED",
                "ERROR",
                throwableChain(t),
                mapOf(
                    "enabledProtocols" to enabledProtocols,
                    "enabledCipherSuites" to enabledCipherSuites,
                    "presentedChain" to (capturingTrustManager?.lastServerChain
                        ?.mapIndexed { index, cert -> certSummary(index, cert) } ?: emptyList<Map<String, Any?>>()),
                    "authType" to capturingTrustManager?.lastAuthType,
                    "trustManagerError" to capturingTrustManager?.lastValidationError
                )
            )
        } catch (t: Throwable) {
            emit(
                "NATIVE_TLS",
                "FAILED",
                "ERROR",
                throwableChain(t),
                mapOf(
                    "enabledProtocols" to enabledProtocols,
                    "enabledCipherSuites" to enabledCipherSuites,
                    "presentedChain" to (capturingTrustManager?.lastServerChain
                        ?.mapIndexed { index, cert -> certSummary(index, cert) } ?: emptyList<Map<String, Any?>>()),
                    "authType" to capturingTrustManager?.lastAuthType,
                    "trustManagerError" to capturingTrustManager?.lastValidationError
                )
            )
        } finally {
            try {
                socket?.close()
            } catch (_: Throwable) {
            }
        }
    }

    private fun probeHttps(url: URL) {
        val safe = safeUrl(url)
        emit("HTTPS", "BEGIN", "INFO", safe)

        var connection: HttpsURLConnection? = null
        try {
            val raw = url.openConnection()
            if (raw !is HttpsURLConnection) {
                emit("HTTPS", "SKIPPED", "WARN", "Không phải HTTPS: $safe")
                return
            }

            connection = raw
            connection.connectTimeout = TIMEOUT_MS
            connection.readTimeout = TIMEOUT_MS
            connection.instanceFollowRedirects = false
            connection.useCaches = false
            connection.requestMethod = "GET"
            connection.setRequestProperty("Accept", "*/*")
            connection.setRequestProperty("User-Agent", "OneVNU-NetworkDiagnostic/1.0")

            val code = connection.responseCode
            val certs = try {
                connection.serverCertificates
                    .filterIsInstance<X509Certificate>()
                    .mapIndexed { index, cert -> certSummary(index, cert) }
            } catch (_: Throwable) {
                emptyList()
            }

            emit(
                "HTTPS",
                "HTTP_REACHED",
                "OK",
                "HTTP $code; cipher=${connection.cipherSuite}",
                mapOf(
                    "url" to safe,
                    "statusCode" to code,
                    "cipher" to connection.cipherSuite,
                    "certificates" to certs
                )
            )

            // Drain a small amount so the connection actually reaches response headers/body.
            try {
                val stream = if (code >= HttpURLConnection.HTTP_BAD_REQUEST) {
                    connection.errorStream
                } else {
                    connection.inputStream
                }
                stream?.use {
                    val buffer = ByteArray(512)
                    it.read(buffer)
                }
            } catch (_: Throwable) {
            }
        } catch (t: SSLHandshakeException) {
            emit("HTTPS", "HANDSHAKE_FAILED", "ERROR", throwableChain(t))
        } catch (t: Throwable) {
            emit("HTTPS", "FAILED", "ERROR", throwableChain(t))
        } finally {
            connection?.disconnect()
        }
    }

    @SuppressLint("SetJavaScriptEnabled")
    private fun probeWebViewBlocking(activity: FlutterFragmentActivity, url: URL) {
        val safe = safeUrl(url)
        emit("WEBVIEW", "BEGIN", "INFO", safe)

        val latch = CountDownLatch(1)
        val completed = AtomicBoolean(false)

        fun finish(stage: String, level: String, message: String, details: Any? = null) {
            if (!completed.compareAndSet(false, true)) return
            emit("WEBVIEW", stage, level, message, details)
            latch.countDown()
        }

        activity.runOnUiThread {
            try {
                val root = activity.findViewById<ViewGroup>(android.R.id.content)
                val webView = WebView(activity)
                webView.alpha = 0.01f
                webView.layoutParams = ViewGroup.LayoutParams(1, 1)
                webView.settings.javaScriptEnabled = false
                webView.settings.domStorageEnabled = false

                val timeoutRunnable = Runnable {
                    finish("TIMEOUT", "ERROR", "WebView không hoàn tất trong thời gian chờ")
                    try {
                        root.removeView(webView)
                        webView.stopLoading()
                        webView.destroy()
                    } catch (_: Throwable) {
                    }
                }

                fun cleanup() {
                    mainHandler.removeCallbacks(timeoutRunnable)
                    try {
                        root.removeView(webView)
                        webView.stopLoading()
                        webView.destroy()
                    } catch (_: Throwable) {
                    }
                }

                webView.webViewClient = object : WebViewClient() {
                    override fun onReceivedSslError(
                        view: WebView?,
                        handler: SslErrorHandler?,
                        error: SslError?
                    ) {
                        // NEVER bypass SSL errors in diagnostics.
                        handler?.cancel()
                        val cert = error?.certificate
                        val details = mapOf(
                            "primaryError" to (error?.primaryError ?: -1),
                            "primaryErrorName" to sslErrorName(error?.primaryError),
                            "url" to safe,
                            "issuedTo" to cert?.issuedTo?.dName,
                            "issuedBy" to cert?.issuedBy?.dName,
                            "validNotBefore" to cert?.validNotBeforeDate?.time,
                            "validNotAfter" to cert?.validNotAfterDate?.time
                        )
                        finish(
                            "SSL_ERROR",
                            "ERROR",
                            "${sslErrorName(error?.primaryError)} (${error?.primaryError ?: -1})",
                            details
                        )
                        cleanup()
                    }

                    override fun onReceivedError(
                        view: WebView?,
                        request: WebResourceRequest?,
                        error: WebResourceError?
                    ) {
                        if (request?.isForMainFrame != true) return
                        finish(
                            "ERROR",
                            "ERROR",
                            "code=${error?.errorCode}; description=${safeText(error?.description?.toString())}",
                            mapOf(
                                "errorCode" to error?.errorCode,
                                "description" to safeText(error?.description?.toString()),
                                "url" to safe
                            )
                        )
                        cleanup()
                    }

                    override fun onReceivedHttpError(
                        view: WebView?,
                        request: WebResourceRequest?,
                        errorResponse: WebResourceResponse?
                    ) {
                        if (request?.isForMainFrame == true) {
                            emit(
                                "WEBVIEW",
                                "HTTP_REACHED",
                                "OK",
                                "HTTP ${errorResponse?.statusCode ?: -1}",
                                mapOf("url" to safe, "statusCode" to errorResponse?.statusCode)
                            )
                        }
                    }

                    override fun onPageFinished(view: WebView?, url: String?) {
                        finish("PAGE_FINISHED", "OK", "WebView đã tải xong: ${safeText(url)}")
                        cleanup()
                    }
                }

                root.addView(webView)
                mainHandler.postDelayed(timeoutRunnable, 12_000)
                webView.loadUrl(url.toString())
            } catch (t: Throwable) {
                finish("FAILED", "ERROR", throwableChain(t))
            }
        }

        try {
            if (!latch.await(14, TimeUnit.SECONDS)) {
                finish("TIMEOUT", "ERROR", "WebView timeout")
            }
        } catch (t: InterruptedException) {
            Thread.currentThread().interrupt()
            finish("INTERRUPTED", "ERROR", throwableChain(t))
        }
    }

    private fun getDeviceInfo(activity: FlutterFragmentActivity): Map<String, Any?> {
        val webViewPackage = try {
            WebView.getCurrentWebViewPackage()
        } catch (_: Throwable) {
            null
        }

        val chromeVersion = packageVersion(activity, "com.android.chrome")

        return mapOf(
            "manufacturer" to Build.MANUFACTURER,
            "brand" to Build.BRAND,
            "model" to Build.MODEL,
            "device" to Build.DEVICE,
            "androidRelease" to Build.VERSION.RELEASE,
            "sdkInt" to Build.VERSION.SDK_INT,
            "securityPatch" to if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) Build.VERSION.SECURITY_PATCH else "",
            "webViewPackage" to webViewPackage?.packageName,
            "webViewVersion" to webViewPackage?.versionName,
            "chromeVersion" to chromeVersion
        )
    }

    @Suppress("DEPRECATION")
    private fun packageVersion(activity: FlutterFragmentActivity, packageName: String): String? {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                activity.packageManager.getPackageInfo(
                    packageName,
                    android.content.pm.PackageManager.PackageInfoFlags.of(0)
                ).versionName
            } else {
                activity.packageManager.getPackageInfo(packageName, 0).versionName
            }
        } catch (_: Throwable) {
            null
        }
    }

    private fun inspectTrustStore(): Map<String, Any?> {
        val store = KeyStore.getInstance("AndroidCAStore")
        store.load(null)

        var count = 0
        var r46 = false
        var r3 = false
        var r6 = false
        val globalSignMatches = mutableListOf<String>()

        val aliases = store.aliases()
        while (aliases.hasMoreElements()) {
            val alias = aliases.nextElement()
            val cert = store.getCertificate(alias) as? X509Certificate ?: continue
            count++
            val subject = cert.subjectX500Principal.name
            val normalized = subject.lowercase(Locale.US)

            if (normalized.contains("globalsign")) {
                if (globalSignMatches.size < 30) {
                    globalSignMatches.add(subject)
                }
                if (normalized.contains("globalSign root r46".lowercase(Locale.US))) r46 = true
                if (normalized.contains("globalSign root r3".lowercase(Locale.US))) r3 = true
                if (normalized.contains("globalSign root r6".lowercase(Locale.US))) r6 = true
            }
        }

        return mapOf(
            "success" to true,
            "certificateCount" to count,
            "globalSignRootR46Present" to r46,
            "globalSignRootR3Present" to r3,
            "globalSignRootR6Present" to r6,
            "globalSignSubjects" to globalSignMatches.distinct()
        )
    }


    private class CapturingTrustManager(
        private val delegate: X509TrustManager
    ) : X509TrustManager {
        @Volatile
        var lastServerChain: Array<X509Certificate>? = null

        @Volatile
        var lastAuthType: String? = null

        @Volatile
        var lastValidationError: String? = null

        override fun checkClientTrusted(chain: Array<out X509Certificate>?, authType: String?) {
            if (chain == null || authType == null) {
                throw CertificateException("Client certificate chain/authType is null")
            }
            delegate.checkClientTrusted(chain, authType)
        }

        override fun checkServerTrusted(chain: Array<out X509Certificate>?, authType: String?) {
            if (chain == null || authType == null) {
                throw CertificateException("Server certificate chain/authType is null")
            }
            lastServerChain = chain.map { it }.toTypedArray()
            lastAuthType = authType
            try {
                delegate.checkServerTrusted(chain, authType)
                lastValidationError = null
            } catch (t: Throwable) {
                lastValidationError = throwableChainStatic(t)
                throw t
            }
        }

        override fun getAcceptedIssuers(): Array<X509Certificate> = delegate.acceptedIssuers

        companion object {
            private fun throwableChainStatic(t: Throwable): String {
                val parts = mutableListOf<String>()
                var current: Throwable? = t
                var depth = 0
                while (current != null && depth < 10) {
                    val message = current.message?.take(1000).orEmpty()
                    parts.add("${current.javaClass.name}${if (message.isNotEmpty()) ": $message" else ""}")
                    current = current.cause
                    depth++
                }
                return parts.joinToString(" -> ")
            }
        }
    }

    private fun certSummary(index: Int, cert: X509Certificate): Map<String, Any?> {
        return mapOf(
            "index" to index,
            "subject" to cert.subjectX500Principal.name,
            "issuer" to cert.issuerX500Principal.name,
            "notBefore" to isoDate(cert.notBefore),
            "notAfter" to isoDate(cert.notAfter),
            "serial" to cert.serialNumber?.toString(16),
            "sigAlg" to cert.sigAlgName,
            "publicKeyAlg" to cert.publicKey?.algorithm
        )
    }

    private fun isoDate(date: Date?): String? {
        if (date == null) return null
        return SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US).apply {
            timeZone = TimeZone.getTimeZone("UTC")
        }.format(date)
    }

    private fun sslErrorName(code: Int?): String {
        return when (code) {
            SslError.SSL_NOTYETVALID -> "SSL_NOTYETVALID"
            SslError.SSL_EXPIRED -> "SSL_EXPIRED"
            SslError.SSL_IDMISMATCH -> "SSL_IDMISMATCH"
            SslError.SSL_UNTRUSTED -> "SSL_UNTRUSTED"
            SslError.SSL_DATE_INVALID -> "SSL_DATE_INVALID"
            SslError.SSL_INVALID -> "SSL_INVALID"
            else -> "SSL_UNKNOWN"
        }
    }

    private fun throwableChain(t: Throwable): String {
        val parts = mutableListOf<String>()
        var current: Throwable? = t
        var depth = 0
        while (current != null && depth < 10) {
            val message = safeText(current.message)
            parts.add("${current.javaClass.name}${if (message.isNotEmpty()) ": $message" else ""}")
            current = current.cause
            depth++
        }
        return parts.joinToString(" -> ")
    }

    private fun safeUrl(url: URL): String {
        val portPart = if (url.port > 0 && url.port != url.defaultPort) ":${url.port}" else ""
        val path = if (url.path.isNullOrEmpty()) "/" else url.path
        return "${url.protocol}://${url.host}$portPart$path"
    }

    private fun safeText(value: String?): String {
        if (value == null) return ""
        return value
            .replace(Regex("(?i)(access_token|refresh_token|authorization|password|ticket|code|state|nonce|bindingsecret)=?[^\\s&]*"), "\$1=<redacted>")
            .take(2_000)
    }

    private fun yesNo(value: Boolean): String = if (value) "CÓ" else "KHÔNG"

    private fun emit(
        scope: String,
        stage: String,
        level: String,
        message: String,
        details: Any? = null
    ) {
        val payload = mutableMapOf<String, Any?>(
            "timestamp" to System.currentTimeMillis(),
            "scope" to scope,
            "stage" to stage,
            "level" to level,
            "message" to safeText(message)
        )
        if (details != null) payload["details"] = details

        mainHandler.post {
            try {
                eventSink?.success(payload)
            } catch (_: Throwable) {
            }
        }
    }
}
